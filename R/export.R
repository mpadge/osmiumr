#' Export OSM data to GeoJSON, geopackage-friendly text, or PostgreSQL COPY format
#'
#' Wraps `osmium export`. Converts OSM nodes/ways/(multipolygon)
#' relations into geometry-bearing features.
#'
#' @param input Path to an input OSM file.
#' @param output Output file path. If NULL, output goes to stdout and is
#'   returned as a character string.
#' @param output_format Output format, e.g. "geojson", "geojsonseq",
#'   "text", "pg" (default depends on `output`'s extension).
#' @param config Path to a JSON config file with export rules (tag
#'   include/exclude lists, attribute selection, ...).
#' @param add_unique_id Add a unique id to each feature: "counter" or
#'   "type_id".
#' @param format_option Character vector of `key=value` output format
#'   options.
#' @param geometry_types Comma-separated geometry types to write, e.g.
#'   "point,linestring,polygon" (the default).
#' @param index_type Node location index type (default "flex_mem"; see
#'   `osmium export --show-index-types`). The anonymous-mmap-backed types
#'   ("sparse_mmap_array", "dense_mmap_array") are Linux-only -- they rely
#'   on `mremap()` to grow, which has no macOS/BSD equivalent -- and are
#'   simply not in the index-type list there.
#' @param keep_untagged If TRUE, also export features without any tags.
#' @param attributes Comma-separated list of OSM attributes to add to
#'   each feature (e.g. "version,timestamp"); none by default.
#' @param show_errors If TRUE, print geometry errors to stdout instead of
#'   silently skipping them.
#' @param stop_on_error If TRUE, stop at the first geometry error instead
#'   of skipping it.
#' @param fsync,overwrite,verbose See [osmium_cat()].
#' @return If `output` is NULL, the written data as a character string.
#'   Otherwise, the `output` path, invisibly.
#' @export
osmium_export <- function(input, output = NULL, output_format = NULL,
                           config = NULL, add_unique_id = NULL,
                           format_option = NULL, geometry_types = NULL,
                           index_type = NULL, keep_untagged = FALSE,
                           attributes = NULL, show_errors = FALSE,
                           stop_on_error = FALSE, overwrite = FALSE,
                           fsync = FALSE, verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)

  args <- character()
  args <- .arg(args, "--config", if (!is.null(config)) normalizePath(config, mustWork = TRUE))
  args <- .arg(args, "--add-unique-id", add_unique_id)
  args <- .arg_multi(args, "--format-option", format_option)
  args <- .flag(args, "--fsync", fsync)
  args <- .arg(args, "--geometry-types", geometry_types)
  args <- .arg(args, "--index-type", index_type)
  args <- .flag(args, "--keep-untagged", keep_untagged)
  args <- .arg(args, "--output", output)
  args <- .arg(args, "--output-format", output_format)
  args <- .flag(args, "--overwrite", overwrite)
  args <- .flag(args, "--show-errors", show_errors)
  args <- .flag(args, "--stop-on-error", stop_on_error)
  args <- .arg(args, "--attributes", attributes)
  args <- .flag(args, "--verbose", verbose)
  args <- c(args, input)

  result <- osmiumr_call("export", args)

  if (is.null(output)) {
    return(result$stdout)
  }
  invisible(output)
}
