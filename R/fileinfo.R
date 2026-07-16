#' Show information about an OSM file
#'
#' Wraps `osmium fileinfo`.
#'
#' @param input Path to an input OSM file.
#' @param extended If TRUE, also scan the whole file to compute extended
#'   statistics (bounding box, counts, CRC, ...), not just the header.
#' @param crc If TRUE, calculate a CRC32 checksum (implies `extended`).
#' @param object_type Character vector of object types to include when
#'   `extended = TRUE`: any of "node", "way", "relation", "changeset".
#' @param get A single dotted variable name (see `osmium help fileinfo` /
#'   `--show-variables`) to retrieve instead of the full report; returned
#'   as a length-1 character string.
#' @param verbose If TRUE, print verbose progress information.
#' @return If `get` is NULL, a nested list parsed from osmium's `--json`
#'   output (via jsonlite). If `get` is supplied, a length-1 character
#'   vector.
#' @export
osmium_fileinfo <- function(input, extended = FALSE, crc = FALSE,
                             object_type = NULL, get = NULL,
                             verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)

  args <- character()
  args <- .flag(args, "--extended", extended)
  args <- .flag(args, "--crc", crc)
  args <- .arg_multi(args, "--object-type", object_type)
  args <- .flag(args, "--verbose", verbose)

  if (!is.null(get)) {
    args <- .arg(args, "--get", get)
    args <- c(args, input)
    result <- rosmium_call("fileinfo", args)
    return(sub("\n$", "", result$stdout))
  }

  args <- c(args, "--json", input)
  result <- rosmium_call("fileinfo", args)
  jsonlite::fromJSON(result$stdout, simplifyVector = TRUE)
}
