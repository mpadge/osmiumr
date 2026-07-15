#' Renumber IDs in an OSM file
#'
#' Wraps `osmium renumber`. Assigns new, small, consecutive IDs to nodes,
#' ways, and relations, remapping all references accordingly. Useful for
#' shrinking ID space after extracting a small area from a large file.
#'
#' @param input Path to an input OSM file.
#' @param output Output file path.
#' @param index_directory Directory to store/reuse the old-ID-to-new-ID
#'   mapping index in (allows renumbering multiple related files
#'   consistently, or resuming). Default: an in-memory-only index.
#' @param start_id Comma-separated first IDs to use for node, way, and
#'   relation numbering, e.g. "1,1,1" (the default). Negative starting
#'   values count down.
#' @param object_type Character vector restricting renumbering to given
#'   object types: any of "node", "way", "relation".
#' @param input_format,overwrite,fsync,generator,output_header,verbose
#'   See [osmium_cat()].
#' @return The `output` path, invisibly.
#' @export
osmium_renumber <- function(input, output = NULL, index_directory = NULL,
                             start_id = NULL, object_type = NULL,
                             input_format = NULL, overwrite = FALSE,
                             fsync = FALSE, generator = NULL,
                             output_header = NULL, verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)

  args <- character()
  args <- .arg(args, "--index-directory", index_directory)
  args <- .arg_multi(args, "--object-type", object_type)
  args <- .arg(args, "--start-id", start_id)
  args <- .flag(args, "--verbose", verbose)
  args <- .arg(args, "--input-format", input_format)
  args <- .output_args(args, output, NULL, overwrite, fsync, generator, output_header)
  args <- c(args, input)

  osmiumr_call("renumber", args)
  invisible(output)
}
