#' Show the contents of an OSM file
#'
#' Wraps `osmium show`. Unlike the standalone CLI, osmiumr always runs as
#' if `--no-pager` was given (see `src/osmium-tool/command_show.cpp` for
#' why) and returns the formatted output as an R character string instead
#' of paging it to a terminal.
#'
#' @param input Path to an input OSM file.
#' @param format c("debug", "opl", "xml") -- output format. "debug" (the
#'   default) is a human-readable, colorized-in-a-terminal debug dump.
#' @param object_type Character vector restricting output to given
#'   object types: any of "node", "way", "relation", "changeset".
#' @param verbose If TRUE, print verbose progress information.
#' @return The formatted file contents as a character string.
#' @export
osmium_show <- function(input, format = c("debug", "opl", "xml"),
                         object_type = NULL, verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)
  format <- match.arg(format)

  args <- character()
  args <- c(args, switch(format,
    debug = "--format-debug",
    opl = "--format-opl",
    xml = "--format-xml"
  ))
  args <- .arg_multi(args, "--object-type", object_type)
  args <- .flag(args, "--verbose", verbose)
  args <- c(args, input)

  result <- osmiumr_call("show", args)
  result$stdout
}
