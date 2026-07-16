#' Sort OSM data files
#'
#' Wraps `osmium sort`. Produces output sorted by type then ID (nodes,
#' then ways, then relations, each ascending by ID), as required by
#' commands like [osmium_merge()].
#'
#' @param input Character vector of one or more input OSM file paths.
#' @param output Output file path.
#' @param strategy "simple" (default) or "multipass" (uses less memory
#'   for very large files at the cost of reading input multiple times;
#'   not compatible with stdin input).
#' @param input_format,overwrite,fsync,generator,output_header,verbose
#'   See [osmium_cat()].
#' @return The `output` path, invisibly.
#' @export
osmium_sort <- function(input, output = NULL,
                         strategy = c("simple", "multipass"),
                         input_format = NULL, overwrite = FALSE,
                         fsync = FALSE, generator = NULL,
                         output_header = NULL, verbose = FALSE) {
  input <- vapply(input, normalizePath, character(1), mustWork = TRUE)
  strategy <- match.arg(strategy)

  args <- character()
  args <- .arg(args, "--strategy", strategy)
  args <- .flag(args, "--verbose", verbose)
  args <- .arg(args, "--input-format", input_format)
  args <- .output_args(args, output, NULL, overwrite, fsync, generator, output_header)
  args <- c(args, input)

  rosmium_call("sort", args)
  invisible(output)
}
