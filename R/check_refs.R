#' Check referential integrity of an OSM file
#'
#' Wraps `osmium check-refs`. Checks that every node referenced by a way
#' (and, optionally, every node/way/relation referenced by a relation) is
#' actually present in the file.
#'
#' @param input Path to an input OSM file.
#' @param show_ids If TRUE, include the IDs of missing objects in the
#'   returned result (parsed from stdout).
#' @param check_relations If TRUE, also check relation members (not just
#'   way nodes).
#' @param verbose If TRUE, print verbose progress information.
#' @return A list with element `ok` (TRUE if no references are missing)
#'   and `missing_ids` (character vector of lines like "n123 in w456",
#'   populated only if `show_ids = TRUE`; empty otherwise).
#' @export
osmium_check_refs <- function(input, show_ids = FALSE,
                               check_relations = FALSE, verbose = FALSE) {
  input <- normalizePath(input, mustWork = TRUE)

  args <- character()
  args <- .flag(args, "--show-ids", show_ids)
  args <- .flag(args, "--check-relations", check_relations)
  args <- .flag(args, "--verbose", verbose)
  args <- c(args, input)

  # check-refs signals "references are missing" via a normal ok = FALSE
  # result (handler.no_errors()), not an exception, so call the bridge
  # directly rather than through osmiumr_call() (which stop()s on ok ==
  # FALSE-as-error only when $error is set, so this is actually fine to
  # route through osmiumr_call() too -- kept explicit here for clarity).
  result <- osmiumr_call("check-refs", args)

  missing_ids <- character()
  if (show_ids && nzchar(result$stdout)) {
    missing_ids <- strsplit(result$stdout, "\n", fixed = TRUE)[[1]]
    missing_ids <- missing_ids[nzchar(missing_ids)]
  }

  list(ok = result$ok, missing_ids = missing_ids, details = result$stderr)
}
