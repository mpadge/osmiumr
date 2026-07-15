#' Concatenate OSM files and convert between formats
#'
#' Wraps `osmium cat`.
#'
#' @param input Character vector of one or more input OSM file paths.
#' @param output Output file path. If NULL, output goes to stdout and is
#'   returned as a character string (see Value).
#' @param output_format Format of the output file (overrides the
#'   extension of `output`), e.g. "pbf", "xml", "opl".
#' @param object_type Character vector restricting output to given
#'   object types: any of "node", "way", "relation", "changeset".
#' @param clean Character vector of attributes to strip from output
#'   objects: any of "version", "changeset", "timestamp", "uid", "user".
#' @param buffer_data If TRUE, buffer all data in memory before writing
#'   (can be faster for multi-file input at the cost of memory).
#' @param input_format Format of the input file(s), if it can't be
#'   detected from the file extension.
#' @param overwrite If TRUE, allow overwriting an existing output file.
#' @param fsync If TRUE, call fsync after writing the output file.
#' @param generator Generator string to record in the output file header.
#' @param output_header Character vector of extra `key=value` header
#'   options to set on the output file.
#' @param verbose If TRUE, print verbose progress information.
#' @return If `output` is NULL, the written data as a character string.
#'   Otherwise, the `output` path, invisibly.
#' @export
osmium_cat <- function(input, output = NULL, output_format = NULL,
                        object_type = NULL, clean = NULL,
                        buffer_data = FALSE, input_format = NULL,
                        overwrite = FALSE, fsync = FALSE,
                        generator = NULL, output_header = NULL,
                        verbose = FALSE) {
  input <- vapply(input, normalizePath, character(1), mustWork = TRUE)

  args <- character()
  args <- .common_args(args, object_type, clean, verbose, input_format)
  args <- .flag(args, "--buffer-data", buffer_data)
  args <- .output_args(args, output, output_format, overwrite, fsync,
                        generator, output_header)
  args <- c(args, input)

  result <- osmiumr_call("cat", args)

  if (is.null(output)) {
    return(result$stdout)
  }
  invisible(output)
}
