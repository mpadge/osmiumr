# Vendored dependencies

Header-only libraries osmium-tool (and thus osmiumr) depends on, vendored
here so building osmiumr doesn't require a system install of any of
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

All three are vendored verbatim/unpatched: none contain the kind of
process-control code (`fork()`/`exec*()`/`exit()`) that required patching
in `../osmium-tool/command_help.cpp` and `../osmium-tool/command_show.cpp`
(the one exception, libosmium's `osmium::io::Reader::execute()` in
`io/reader.hpp`, which forks and execs `curl` to read remote XAPI URLs,
is already `#ifndef _WIN32`-guarded by libosmium itself and is, on POSIX,
unreachable through osmiumr's public API since every R wrapper validates
its input as an existing local file via `normalizePath(mustWork = TRUE)`
before any C++ code runs).

Re-vendoring for a version bump: replace the relevant subdirectory's
`include/` tree wholesale from a fresh upstream checkout (don't hand-edit
individual files), update the version/date in this table, and re-run the
safety audit this table's last paragraph describes
(`grep -rn "std::exit\|::exit(\| abort()\|execlp\|execvp\|::fork(\|_exit("`)
against the new tree before committing.
