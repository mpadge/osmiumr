
// osmiumr note: adapted from osmium-tool/src/version.cpp.in. Upstream fills
// in @PROJECT_VERSION@/@VERSION_FROM_GIT@ via CMake's configure_file() +
// `git describe`. osmiumr vendors a fixed snapshot of osmium-tool rather
// than building from its git checkout, so the version string is hardcoded
// here instead; bump OSMIUM_TOOL_VENDORED_VERSION when re-vendoring from a
// newer osmium-tool release.

#include <osmium/version.hpp>

#define OSMIUM_TOOL_VENDORED_VERSION "1.19.1"

const char* get_osmium_version() noexcept {
    return OSMIUM_TOOL_VENDORED_VERSION;
}

const char* get_osmium_long_version() noexcept {
    return "osmium version " OSMIUM_TOOL_VENDORED_VERSION " (vendored into osmiumr)";
}

const char* get_libosmium_version() noexcept {
    return "libosmium version " LIBOSMIUM_VERSION_STRING;
}
