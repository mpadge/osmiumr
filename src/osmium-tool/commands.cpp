
#include "cmd.hpp"

// osmiumr note: this file is adapted from osmium-tool/src/commands.cpp.
// register_commands() here only wires up the Phase 1 subset of commands
// vendored into this package (see ../../plan.md). Add the remaining
// command_*.hpp includes/registrations here as later phases vendor them.

#include "command_cat.hpp"
#include "command_check_refs.hpp"
#include "command_export.hpp"
#include "command_extract.hpp"
#include "command_fileinfo.hpp"
#include "command_getid.hpp"
#include "command_help.hpp"
#include "command_merge.hpp"
#include "command_renumber.hpp"
#include "command_show.hpp"
#include "command_sort.hpp"
#include "command_tags_filter.hpp"

void register_commands(CommandFactory& cmd_factory) {
    cmd_factory.register_command("cat", "Concatenate OSM files and convert to different formats", [&]() {
        return std::make_unique<CommandCat>(cmd_factory);
    });

    cmd_factory.register_command("check-refs", "Check referential integrity of an OSM file", [&]() {
        return std::make_unique<CommandCheckRefs>(cmd_factory);
    });

    cmd_factory.register_command("export", "Export OSM data", [&]() {
        return std::make_unique<CommandExport>(cmd_factory);
    });

    cmd_factory.register_command("extract", "Create geographic extract", [&]() {
        return std::make_unique<CommandExtract>(cmd_factory);
    });

    cmd_factory.register_command("fileinfo", "Show information about OSM file", [&]() {
        return std::make_unique<CommandFileinfo>(cmd_factory);
    });

    cmd_factory.register_command("getid", "Get objects with given ID from OSM file", [&]() {
        return std::make_unique<CommandGetId>(cmd_factory);
    });

    cmd_factory.register_command("help", "Show osmium help", [&]() {
        return std::make_unique<CommandHelp>(cmd_factory);
    });

    cmd_factory.register_command("merge", "Merge several sorted OSM files into one", [&]() {
        return std::make_unique<CommandMerge>(cmd_factory);
    });

    cmd_factory.register_command("renumber", "Renumber IDs in OSM file", [&]() {
        return std::make_unique<CommandRenumber>(cmd_factory);
    });

    cmd_factory.register_command("show", "Show OSM file contents", [&]() {
        return std::make_unique<CommandShow>(cmd_factory);
    });

    cmd_factory.register_command("sort", "Sort OSM data files", [&]() {
        return std::make_unique<CommandSort>(cmd_factory);
    });

    cmd_factory.register_command("tags-filter", "Filter OSM data based on tags", [&]() {
        return std::make_unique<CommandTagsFilter>(cmd_factory);
    });
}
