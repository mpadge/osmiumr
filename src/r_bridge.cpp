// rosmium: in-process bridge between R and osmium-tool's Command classes
// (vendored, lightly adapted, under src/osmium-tool/ — see ../plan.md).
//
// This file plays the role that osmium-tool/src/main.cpp plays for the
// standalone CLI: it looks a command up in the CommandFactory, calls
// setup() then run(), and translates the result back to the caller. It
// does not vendor main.cpp itself, since main.cpp's argv[0]-sniffing and
// process exit-code handling don't apply when called as a library function.
//
// osmium's data readers/writers write "-" (stdin/stdout) via raw fd-level
// I/O (write(2)/dup(2)), bypassing C++ std::cout entirely (see
// osmium/io/detail/read_write.hpp), while osmium-tool's VerboseOutput and
// error messages go through real std::cout/std::cerr. StdFdCapture below
// redirects the OS-level file descriptors 1 and 2 for the duration of a
// command, which catches both cases uniformly.

#include "osmium-tool/cmd.hpp"

#include <osmium/geom/factory.hpp>
#include <osmium/handler/check_order.hpp>
#include <osmium/io/pbf.hpp>
#include <osmium/osm/location.hpp>
#include <osmium/thread/pool.hpp>

#include <boost/program_options.hpp> // rosmium's own shim; see src/compat/boost/program_options.hpp

#include <Rcpp.h>

#include <cstdio>
#include <ios>
#include <iostream>
#include <memory>
#include <string>
#include <system_error>
#include <vector>

#ifdef _WIN32
# include <io.h>
# define ROSMIUM_DUP _dup
# define ROSMIUM_DUP2 _dup2
# define ROSMIUM_FILENO _fileno
#else
# include <unistd.h>
# define ROSMIUM_DUP dup
# define ROSMIUM_DUP2 dup2
# define ROSMIUM_FILENO fileno
#endif

namespace {

// RAII redirect of real stdout/stderr (fd 1 / fd 2) to anonymous temp
// files, so output written by osmium's fd-level I/O and by std::cout/
// std::cerr during a Command's setup()/run() can be captured and handed
// back to R instead of escaping to whatever fds 1/2 happen to be bound to
// in the host R process.
class StdFdCapture {
public:
    StdFdCapture() {
        // rosmium note: upstream (our own r_bridge.cpp) also had explicit
        // std::cout.flush()/std::cerr.flush() calls here. Removed: they
        // were the only two remaining std::cout/std::cerr symbol
        // references in this file (see plan-cout.md Step 2) and are
        // redundant with std::fflush(nullptr) below -- sync_with_stdio is
        // never disabled anywhere in this package (grep -rn
        // "sync_with_stdio" src/ returns nothing), so std::cout/std::cerr
        // share their buffer with C stdio's stdout/stderr, meaning
        // std::fflush(nullptr) (which flushes every open C stdio stream)
        // already flushes any pending std::cout/std::cerr content too.
        std::fflush(nullptr);

        saved_stdout_ = ROSMIUM_DUP(1);
        saved_stderr_ = ROSMIUM_DUP(2);

        stdout_file_ = std::tmpfile();
        stderr_file_ = std::tmpfile();

        if (stdout_file_) {
            ROSMIUM_DUP2(ROSMIUM_FILENO(stdout_file_), 1);
        }
        if (stderr_file_) {
            ROSMIUM_DUP2(ROSMIUM_FILENO(stderr_file_), 2);
        }
    }

    StdFdCapture(const StdFdCapture&) = delete;
    StdFdCapture& operator=(const StdFdCapture&) = delete;

    ~StdFdCapture() {
        restore();
        if (stdout_file_) {
            std::fclose(stdout_file_);
        }
        if (stderr_file_) {
            std::fclose(stderr_file_);
        }
        if (saved_stdout_ >= 0) {
            ::close(saved_stdout_);
        }
        if (saved_stderr_ >= 0) {
            ::close(saved_stderr_);
        }
    }

    // Flushes and restores the original fds. Safe to call before reading
    // back captured text; safe to call again (as a no-op) from the
    // destructor.
    void restore() {
        if (restored_) {
            return;
        }
        std::fflush(nullptr);
        if (saved_stdout_ >= 0) {
            ROSMIUM_DUP2(saved_stdout_, 1);
        }
        if (saved_stderr_ >= 0) {
            ROSMIUM_DUP2(saved_stderr_, 2);
        }
        restored_ = true;
    }

    std::string stdout_text() {
        restore();
        return read_all(stdout_file_);
    }

    std::string stderr_text() {
        restore();
        return read_all(stderr_file_);
    }

private:
    static std::string read_all(FILE* f) {
        if (!f) {
            return {};
        }
        std::fflush(f);
        const long size = std::ftell(f);
        std::string result;
        if (size > 0) {
            result.resize(static_cast<std::size_t>(size));
            std::rewind(f);
            const std::size_t n = std::fread(&result[0], 1, static_cast<std::size_t>(size), f);
            result.resize(n);
        }
        return result;
    }

    FILE* stdout_file_ = nullptr;
    FILE* stderr_file_ = nullptr;
    int saved_stdout_ = -1;
    int saved_stderr_ = -1;
    bool restored_ = false;

}; // class StdFdCapture

// Every osmium::io::Reader/Writer created inside a Command's setup()/run()
// falls back to osmium::thread::Pool::default_instance() (see
// vendor/libosmium/include/osmium/thread/pool.hpp for why that pool must
// not be left to join its worker threads via ordinary static-teardown on
// process exit). Constructing this guard first in rosmium_run() means it
// is destroyed last, after cmd and every Reader/Writer it created have
// already gone out of scope, so the join below happens synchronously in
// this call rather than at process/DLL exit.
struct PoolShutdownGuard {
    ~PoolShutdownGuard() {
        osmium::thread::Pool::shutdown_default_instance();
    }
};

} // anonymous namespace

//' Run an osmium-tool command in-process
//'
//' Internal bridge to the vendored osmium-tool Command classes. Not
//' intended to be called directly by package users; see the per-command
//' wrapper functions (osmium_cat(), osmium_extract(), ...) instead.
//'
//' @param command Command name, e.g. "cat", "extract", "fileinfo".
//' @param args Character vector of command-line-style arguments, in the
//'   same shape as the corresponding `osmium <command> ...` invocation
//'   (without the leading command name).
//' @return A list with elements ok (logical), ran (logical, whether run()
//'   was reached at all), error (string or NULL), stdout (string), stderr
//'   (string).
// [[Rcpp::export]]
Rcpp::List rosmium_run(std::string command, std::vector<std::string> args) {
    PoolShutdownGuard pool_guard;

    CommandFactory factory;
    register_commands(factory);

    std::unique_ptr<Command> cmd = factory.create_command(command);
    if (!cmd) {
        Rcpp::stop("Unknown osmium command '" + command + "'.");
    }

    bool ok = false;
    bool ran = false;
    std::string error_message;

    StdFdCapture capture;
    try {
        if (cmd->setup(args)) {
            ran = true;
            ok = cmd->run();
        } else {
            // setup() returned false for requests like --help, where the
            // command has already printed what it needed to and there is
            // nothing further to run.
            ok = true;
        }
    } catch (const boost::program_options::error& e) {
        error_message = std::string("Error parsing command line: ") + e.what();
    } catch (const std::bad_alloc&) {
        error_message = "Out of memory.";
    } catch (const osmium::out_of_order_error& e) {
        error_message = std::string(e.what()) +
            " This command expects the input file to be ordered: first nodes "
            "in order of ID, then ways in order of ID, then relations in "
            "order of ID.";
    } catch (const std::system_error& e) {
        error_message = e.what();
    } catch (const osmium::geometry_error& e) {
        error_message = std::string("Geometry error: ") + e.what();
    } catch (const osmium::invalid_location&) {
        error_message = "Geometry error: Invalid location. Usually this "
            "means a node was missing from the input data.";
    } catch (const std::exception& e) {
        error_message = e.what();
    }

    return Rcpp::List::create(
        Rcpp::Named("ok") = ok,
        Rcpp::Named("ran") = ran,
        Rcpp::Named("error") = error_message.empty() ? R_NilValue : Rcpp::wrap(error_message),
        Rcpp::Named("stdout") = capture.stdout_text(),
        Rcpp::Named("stderr") = capture.stderr_text()
    );
}

//' List commands registered with the vendored osmium-tool CommandFactory
//' @return character vector of command names
// [[Rcpp::export]]
Rcpp::CharacterVector rosmium_registered_commands() {
    CommandFactory factory;
    register_commands(factory);

    const auto commands = factory.help();
    Rcpp::CharacterVector out(commands.size());
    Rcpp::CharacterVector descriptions(commands.size());
    for (std::size_t i = 0; i < commands.size(); ++i) {
        out[i] = commands[i].first;
        descriptions[i] = commands[i].second;
    }
    out.attr("names") = descriptions;
    return out;
}
