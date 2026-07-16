#' Create a geographic extract from an OSM file
#'
#' Wraps `osmium extract`. Exactly one of `bbox`, `polygon`, or `config`
#' must be given.
#'
#' @param input Path to an input OSM file.
#' @param output Output file path. Ignored (with a warning from osmium)
#'   if `config` is given, since a config file specifies its own
#'   per-extract outputs.
#' @param bbox Numeric vector of length 4: `c(left, bottom, right, top)`
#'   (i.e. min lon, min lat, max lon, max lat).
#' @param polygon Path to a polygon file (`.poly` format or a GeoJSON/OSM
#'   file with a single (multi)polygon) describing the extract boundary.
#' @param config Path to a JSON config file describing one or more
#'   extracts (see `osmium help extract`); when given, `directory`,
#'   `output`, and `output_format` come from the config file instead.
#' @param directory Output directory for extracts defined via `config`.
#' @param strategy Extract strategy: "complete_ways" (default, keeps
#'   ways with any node in the area, adding missing nodes), "simple"
#'   (cuts ways at the boundary), or "smart" (like complete_ways but
#'   also completes multipolygon relations).
#' @param option Character vector of `key=value` strategy options (`-S`).
#' @param with_history If TRUE, input and output are OSM history files.
#' @param set_bounds If TRUE, set the extract's bounding box in the
#'   output file header.
#' @param clean Character vector of attributes to strip: any of
#'   "version", "changeset", "timestamp", "uid", "user".
#' @param input_format,overwrite,fsync,generator,output_header,verbose
#'   See [osmium_cat()].
#' @return The `output` path (or `directory`, if `config` was used),
#'   invisibly.
#' @export
osmium_extract <- function(input, output = NULL, bbox = NULL,
                            polygon = NULL, config = NULL,
                            directory = NULL,
                            strategy = c("complete_ways", "simple", "smart"),
                            option = NULL, with_history = FALSE,
                            set_bounds = FALSE, clean = NULL,
                            input_format = NULL, overwrite = FALSE,
                            fsync = FALSE, generator = NULL,
                            output_header = NULL, verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)
  strategy <- match.arg(strategy)

  n_sources <- sum(!is.null(bbox), !is.null(polygon), !is.null(config))
  if (n_sources != 1) {
    stop("Provide exactly one of `bbox`, `polygon`, or `config`.", call. = FALSE)
  }

  args <- character()
  if (!is.null(bbox)) {
    if (length(bbox) != 4) stop("`bbox` must have length 4: c(left, bottom, right, top).", call. = FALSE)
    args <- .arg(args, "--bbox", paste(bbox, collapse = ","))
  }
  if (!is.null(polygon)) {
    args <- .arg(args, "--polygon", normalizePath(polygon, mustWork = TRUE))
  }
  if (!is.null(config)) {
    args <- .arg(args, "--config", normalizePath(config, mustWork = TRUE))
  }
  args <- .arg(args, "--directory", directory)
  args <- .arg(args, "--strategy", strategy)
  args <- .arg_multi(args, "--option", option)
  args <- .flag(args, "--with-history", with_history)
  args <- .flag(args, "--set-bounds", set_bounds)
  args <- .arg_multi(args, "--clean", clean)
  args <- .flag(args, "--verbose", verbose)
  args <- .arg(args, "--input-format", input_format)
  args <- .output_args(args, output, NULL, overwrite, fsync, generator, output_header)
  args <- c(args, input)

  rosmium_call("extract", args)
  invisible(if (!is.null(config)) directory else output)
}
