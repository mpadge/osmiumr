#' Filter OSM data based on tag expressions
#'
#' Wraps `osmium tags-filter`. Keeps objects matching one or more filter
#' expressions (plus, by default, any objects they reference), optionally
#' inverting the match or stripping tags from non-matching objects.
#'
#' @param input Path to an input OSM file.
#' @param output Output file path.
#' @param expressions Character vector of filter expressions (see
#'   `osmium help tags-filter` for expression syntax, e.g.
#'   `"n/amenity=cafe"` or `"w/highway"`). Ignored if `expressions_file`
#'   is given.
#' @param expressions_file Path to a file with one filter expression per
#'   line, used instead of `expressions`.
#' @param invert_match If TRUE, keep objects that do NOT match.
#' @param omit_referenced If TRUE, don't automatically pull in objects
#'   referenced by matching objects (e.g. a way's nodes).
#' @param remove_tags If TRUE, strip tags from objects kept only because
#'   they're referenced by a matching object.
#' @param object_type Character vector restricting output to given
#'   object types: any of "node", "way", "relation".
#' @param input_format,overwrite,fsync,generator,output_header,verbose
#'   See [osmium_cat()].
#' @return The `output` path, invisibly.
#' @export
osmium_tags_filter <- function(input, output, expressions = NULL,
                                expressions_file = NULL,
                                invert_match = FALSE,
                                omit_referenced = FALSE,
                                remove_tags = FALSE, object_type = NULL,
                                input_format = NULL, overwrite = FALSE,
                                fsync = FALSE, generator = NULL,
                                output_header = NULL, verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)

  args <- character()
  args <- .common_args(args, object_type, NULL, verbose, input_format)
  args <- .flag(args, "--invert-match", invert_match)
  args <- .flag(args, "--omit-referenced", omit_referenced)
  args <- .flag(args, "--remove-tags", remove_tags)
  args <- .output_args(args, output, NULL, overwrite, fsync, generator, output_header)

  if (!is.null(expressions_file)) {
    args <- .arg(args, "--expressions", normalizePath(expressions_file, mustWork = TRUE))
    args <- c(args, input)
  } else {
    if (is.null(expressions) || length(expressions) == 0) {
      stop("Provide either `expressions` or `expressions_file`.", call. = FALSE)
    }
    args <- c(args, input, expressions)
  }

  osmiumr_call("tags-filter", args)
  invisible(output)
}
