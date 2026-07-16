# Vendored dependencies

Header-only libraries osmium-tool (and thus rosmium) depends on, vendored
here so building rosmium doesn't require a system install of any of
them on any platform (see `../../plan-windows.md` for why: Windows in
particular has no standard system location for these, unlike
Linux/macOS package managers). All three are permissively licensed and
their inclusion in this GPL-3 package is unproblematic; see each
subdirectory's license file(s) for the full text.

| Directory | Library | Version | License | Upstream |
|---|---|---|---|---|
| `libosmium/` | libosmium | 2.23.1 | Boost Software License 1.0 | https://github.com/osmcode/libosmium |
| `nlohmann/` | nlohmann/json (single-header amalgamation) | 3.12.0 | MIT | https://github.com/nlohmann/json |
| `protozero/` | protozero | 1.8.2 | BSD-2-Clause (+ Apache-2.0 for one folly-derived file, see `protozero/LICENSE.from_folly`) | https://github.com/mapbox/protozero |

All three are otherwise vendored verbatim/unpatched with two exceptions:
process-control code (`fork()`/`exec*()`/`exit()`) that required patching
in `../osmium-tool/command_help.cpp` and `../osmium-tool/command_show.cpp`
(the one library-internal case, libosmium's `osmium::io::Reader::execute()`
in `io/reader.hpp`, which forks and execs `curl` to read remote XAPI URLs,
is already `#ifndef _WIN32`-guarded by libosmium itself and is, on POSIX,
unreachable through rosmium's public API since every R wrapper validates
its input as an existing local file via `normalizePath(mustWork = TRUE)`
before any C++ code runs); and `libosmium/include/osmium/thread/pool.hpp`,
patched to add `Pool::shutdown_default_instance()` (see the "rosmium
patch" comments there and the `PoolShutdownGuard` in `../r_bridge.cpp`
that calls it after every command). Without that patch, the default
thread pool's worker threads are only joined in `~Pool()`, which for a
plain function-local static only runs during static/DLL teardown at
process exit -- joining that late deadlocks on Windows (loader lock held
during `DLL_PROCESS_DETACH`), which hung every Windows CI job for this
package for exactly the 6-hour GitHub Actions job timeout even though
the R-level test run had long since finished.

Re-vendoring for a version bump: replace the relevant subdirectory's
`include/` tree wholesale from a fresh upstream checkout (don't hand-edit
individual files), update the version/date in this table, re-apply the
`pool.hpp` patch above (diff it against the current vendored copy first
to see exactly what to reapply), and re-run the safety audit this
paragraph describes
(`grep -rn "std::exit\|::exit(\| abort()\|execlp\|execvp\|::fork(\|_exit(\|std::thread\|::default_instance("`)
against the new tree before committing -- the `std::thread`/
`default_instance(` additions are there because the grep pattern that
caught the `fork()`/`exec*()` cases above did not catch this one.
