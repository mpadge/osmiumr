#' Merge several sorted OSM files into one
#'
#' Wraps `osmium merge`. Input files must each be sorted by type then ID
#' (as `osmium sort` produces).
#'
#' @param input Character vector of two or more input OSM file paths.
#' @param output Output file path.
#' @param with_history If TRUE, suppress the warning about input files
#'   containing multiple versions of the same object.
#' @param input_format,overwrite,fsync,generator,output_header,verbose
#'   See [osmium_cat()].
#' @return The `output` path, invisibly.
#' @export
osmium_merge <- function(input, output = NULL, with_history = FALSE,
                          input_format = NULL, overwrite = FALSE,
                          fsync = FALSE, generator = NULL,
                          output_header = NULL, verbose = FALSE) {
  input <- vapply(input, normalizePath, character(1), mustWork = TRUE)

  args <- character()
  args <- .flag(args, "--with-history", with_history)
  args <- .flag(args, "--verbose", verbose)
  args <- .arg(args, "--input-format", input_format)
  args <- .output_args(args, output, NULL, overwrite, fsync, generator, output_header)
  args <- c(args, input)

  rosmium_call("merge", args)
  invisible(output)
}
