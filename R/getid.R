#' Get objects with given IDs from an OSM file
#'
#' Wraps `osmium getid`. IDs are prefixed with their object type: "n" for
#' node, "w" for way, "r" for relation (e.g. "n123", "w456", "r789"); an
#' unprefixed ID uses `default_type`.
#'
#' @param input Path to an input OSM file.
#' @param output Output file path.
#' @param ids Character vector of (optionally type-prefixed) OSM IDs to
#'   extract.
#' @param id_file Character vector of paths to text files with one
#'   (optionally type-prefixed) ID per line, read in addition to `ids`.
#' @param id_osm_file Character vector of paths to OSM files whose
#'   contained object IDs should be used, read in addition to `ids`.
#' @param default_type Default object type ("node", "way", or
#'   "relation") for IDs in `ids`/`id_file` that have no type prefix.
#' @param add_referenced If TRUE, recursively add objects referenced by
#'   the requested objects (way nodes, relation members). Required
#'   whenever `input` is not a regular file path (can't read from stdin
#'   with this option).
#' @param with_history If TRUE, treat `input` as an OSM history file.
#' @param remove_tags If TRUE, strip tags from objects pulled in only
#'   because they're referenced (has no effect unless
#'   `add_referenced = TRUE`).
#' @param verbose_ids If TRUE, print all requested and missing IDs
#'   (implies `verbose`).
#' @param input_format,overwrite,fsync,generator,output_header,verbose
#'   See [osmium_cat()].
#' @return The `output` path, invisibly.
#' @export
osmium_getid <- function(input, output, ids = NULL, id_file = NULL,
                          id_osm_file = NULL, default_type = NULL,
                          add_referenced = FALSE, with_history = FALSE,
                          remove_tags = FALSE, verbose_ids = FALSE,
                          input_format = NULL, overwrite = FALSE,
                          fsync = FALSE, generator = NULL,
                          output_header = NULL, verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)

  if (is.null(ids) && is.null(id_file) && is.null(id_osm_file)) {
    stop("Provide at least one of `ids`, `id_file`, or `id_osm_file`.", call. = FALSE)
  }

  args <- character()
  args <- .arg(args, "--default-type", default_type)
  args <- .arg_multi(args, "--id-file", id_file)
  args <- .arg_multi(args, "--id-osm-file", id_osm_file)
  args <- .flag(args, "--with-history", with_history)
  args <- .flag(args, "--add-referenced", add_referenced)
  args <- .flag(args, "--remove-tags", remove_tags)
  args <- .flag(args, "--verbose-ids", verbose_ids)
  args <- .flag(args, "--verbose", verbose)
  args <- .arg(args, "--input-format", input_format)
  args <- .output_args(args, output, NULL, overwrite, fsync, generator, output_header)
  args <- c(args, input, ids)

  osmiumr_call("getid", args)
  invisible(output)
}
