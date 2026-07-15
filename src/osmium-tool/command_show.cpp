/*

Osmium -- OpenStreetMap data manipulation command line tool
https://osmcode.org/osmium-tool/

Copyright (C) 2013-2026  Jochen Topf <jochen@topf.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/

#include "command_show.hpp"

#include "exception.hpp"
#include "util.hpp"

#include <osmium/io/file.hpp>
#include <osmium/io/header.hpp>
#include <osmium/io/reader.hpp>
#include <osmium/io/writer.hpp>
#include <osmium/memory/buffer.hpp>
#include <osmium/util/verbose_output.hpp>

#include <boost/program_options.hpp>

#include <cerrno>
#include <csignal>
#include <cstdlib>
#include <string>
#include <system_error>
#include <utility>
#include <vector>

#ifndef _WIN32
# include <unistd.h>
#endif

// osmiumr note: upstream osmium-tool can fork()+execlp() an external pager
// (e.g. `less`) here and redirect the process's real stdout fd into its
// pipe. Forking and reassigning file descriptor 1 out from under a
// long-running host process (an R session, potentially multi-threaded) is
// not safe here, so paging support has been removed entirely: osmiumr
// always behaves as if --no-pager was given, and setup_pager_from_env() is
// a no-op that leaves m_pager empty.
#ifndef _WIN32
void CommandShow::setup_pager_from_env() noexcept {
    m_pager.clear();
}
#endif

bool CommandShow::setup(const std::vector<std::string>& arguments) {
    po::options_description opts_cmd{"COMMAND OPTIONS"};
    opts_cmd.add_options()
    ("format-debug,d", "Use debug format")
    ("format-opl,o", "Use OPL format")
    ("format-xml,x", "Use XML format")
#ifndef _WIN32
    ("no-pager", "Do not run pager program")
#endif
    ("object-type,t", po::value<std::vector<std::string>>(), "Read only objects of given type (node, way, relation, changeset)")
    ("output-format,f", po::value<std::string>(), "Format of output file")
    ;

    const po::options_description opts_common{add_common_options(false)};
    const po::options_description opts_input{add_single_input_options()};

    po::options_description hidden;
    hidden.add_options()
    ("input-filename", po::value<std::string>(), "Input file")
    ;

    po::options_description desc;
    desc.add(opts_cmd).add(opts_common).add(opts_input);

    po::options_description parsed_options;
    parsed_options.add(desc).add(hidden);

    po::positional_options_description positional;
    positional.add("input-filename", 1);

    po::variables_map vm;
    po::store(po::command_line_parser(arguments).options(parsed_options).positional(positional).run(), vm);
    po::notify(vm);

    if (!setup_common(vm, desc)) {
        return false;
    }
    setup_object_type_nwrc(vm);
    setup_input_file(vm);

#ifndef _WIN32
    if (vm.count("no-pager")) {
        m_pager = "";
    } else {
        setup_pager_from_env();
    }
#endif

    if (vm.count("output-format") &&
        vm.count("format-debug") &&
        vm.count("format-opl") &&
        vm.count("format-xml")) {
        throw argument_error{"You can only use at most one of the following options: --output-format/-f, --format-debug/-d, --format-opl/-o, and --format-xml/-x."};
    }

    if (vm.count("output-format")) {
        m_output_format = vm["output-format"].as<std::string>();
    } else if (vm.count("format-debug")) {
        m_output_format = "debug,color=true";
    } else if (vm.count("format-opl")) {
        m_output_format = "opl";
    } else if (vm.count("format-xml")) {
        m_output_format = "xml";
    } else {
        const char* output_format_from_env = ::getenv("OSMIUM_SHOW_FORMAT"); // NOLINT(concurrency-mt-unsafe)
        if (output_format_from_env) {
            m_output_format = output_format_from_env;
        }
    }

    m_color_output = m_output_format.find("color=true") != std::string::npos;

    return true;
}

void CommandShow::show_arguments() {
    show_single_input_arguments(m_vout);
    m_vout << "  other options:\n";
    m_vout << "    file format: " << m_output_format << "\n";
    m_vout << "    use color: " << yes_no(m_color_output);
    m_vout << "    use pager: " << (m_pager.empty() ? "(no pager)" : m_pager) << "\n";
    show_object_types(m_vout);
}

bool CommandShow::run() {
    osmium::io::Reader reader{m_input_file, osm_entity_bits()};
    const osmium::io::Header header{reader.header()};

    {
        // osmiumr note: upstream also had a branch here that piped output
        // through an external pager (see setup_pager_from_env() above for
        // why that was removed). m_pager is now always empty, so this is
        // always the direct-write path. Output goes to the OS-level stdout
        // file descriptor (osmium::io::File{"-", ...} writes via raw
        // write(2), not std::cout), which the R bridge captures by
        // redirecting fd 1 for the duration of the call.
        const osmium::io::File file{"-", m_output_format};
        osmium::io::Writer writer{file, header};
        while (osmium::memory::Buffer buffer = reader.read()) {
            writer(std::move(buffer));
        }
        writer.close();
    }

    reader.close();

    return true;
}

