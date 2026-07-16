#' Run rosmium_run() while also capturing R-console-level output
#'
#' Most vendored command output goes through raw OS file descriptor
#' writes or std::cout/std::cerr, both caught by the C++-side
#' StdFdCapture in r_bridge.cpp (see its result$stdout/result$stderr).
#' But some vendored code (see plan.md's "R CMD check status" section)
#' was converted to Rcpp::Rcout/Rcpp::Rcerr instead, which write through
#' R's own console/connection mechanism rather than to a file descriptor
#' -- StdFdCapture can't see that. sink() with a textConnection() does
#' intercept it (Rcpp::Rcout goes through the same path as Rprintf,
#' which sink(type = "output") captures; Rcpp::Rcerr through the same
#' path as message(), captured by sink(type = "message")), so this
#' wraps every call in one and merges the result with what StdFdCapture
#' already caught. The two never double-capture the same bytes: once
#' something is converted to Rcpp::Rcout/Rcerr it no longer touches the
#' OS file descriptor at all.
#' @noRd
.rosmium_run_captured <- function(command, args) {
  rcout_lines <- character()
  rcerr_lines <- character()
  rcout_conn <- textConnection("rcout_lines", "w", local = TRUE)
  rcerr_conn <- textConnection("rcerr_lines", "w", local = TRUE)

  sink(rcout_conn, type = "output")
  sink(rcerr_conn, type = "message")
  result <- tryCatch(
    rosmium_run(command, args),
    finally = {
      sink(type = "message")
      sink(type = "output")
      close(rcout_conn)
      close(rcerr_conn)
    }
  )

  result$stdout <- paste0(result$stdout, paste(rcout_lines, collapse = "\n"))
  result$stderr <- paste0(result$stderr, paste(rcerr_lines, collapse = "\n"))
  result
}

#' Run a vendored osmium-tool command and stop() on failure
#'
#' @param command Command name (e.g. "cat", "extract").
#' @param args Character vector of CLI-style arguments.
#' @param quiet If FALSE, captured stdout/stderr text is relayed through
#'   `message()` after the call (mirroring what would appear in a terminal).
#' @return The list returned by the C++ bridge (invisibly), with elements
#'   ok, ran, error, stdout, stderr.
#' @keywords internal
#' @noRd
rosmium_call <- function(command, args, quiet = TRUE) {
  args <- as.character(args)
  result <- .rosmium_run_captured(command, args)

  if (!quiet) {
    if (nzchar(result$stdout)) message(result$stdout, appendLF = FALSE)
    if (nzchar(result$stderr)) message(result$stderr, appendLF = FALSE)
  }

  if (!is.null(result$error)) {
    stop(
      sprintf("osmium %s: %s", command, result$error),
      if (nzchar(result$stderr)) paste0("\n", result$stderr) else "",
      call. = FALSE
    )
  }

  invisible(result)
}

#' Append a flag/value pair to an argument vector if value is not NULL
#' @noRd
.arg <- function(args, flag, value) {
  if (is.null(value)) {
    return(args)
  }
  c(args, flag, as.character(value))
}

#' Append a bare flag to an argument vector if condition is TRUE
#' @noRd
.flag <- function(args, flag, condition) {
  if (isTRUE(condition)) {
    return(c(args, flag))
  }
  args
}

#' Append one flag/value pair per element of a vector value
#' @noRd
.arg_multi <- function(args, flag, values) {
  if (is.null(values)) {
    return(args)
  }
  for (v in values) {
    args <- c(args, flag, as.character(v))
  }
  args
}

#' Common object-type / clean / verbose / input-format options shared by
#' most commands
#' @noRd
.common_args <- function(args, object_type = NULL, clean = NULL,
                          verbose = FALSE, input_format = NULL) {
  args <- .arg_multi(args, "--object-type", object_type)
  args <- .arg_multi(args, "--clean", clean)
  args <- .flag(args, "--verbose", verbose)
  args <- .arg(args, "--input-format", input_format)
  args
}

#' Common output options shared by commands that write an OSM file
#' @noRd
.output_args <- function(args, output = NULL, output_format = NULL,
                          overwrite = FALSE, fsync = FALSE,
                          generator = NULL, output_header = NULL) {
  args <- .arg(args, "--output", output)
  args <- .arg(args, "--output-format", output_format)
  args <- .flag(args, "--overwrite", overwrite)
  args <- .flag(args, "--fsync", fsync)
  args <- .arg(args, "--generator", generator)
  args <- .arg_multi(args, "--output-header", output_header)
  args
}
