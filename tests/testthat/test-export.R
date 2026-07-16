test_that("export to geojson returns valid GeoJSON text on stdout", {
  text <- osmium_export(fixture("denmark-mini.osm.pbf"), output_format = "geojson")
  parsed <- jsonlite::fromJSON(text, simplifyVector = FALSE)
  expect_equal(parsed$type, "FeatureCollection")
  expect_gt(length(parsed$features), 0)
})

test_that("export writes to an output file when given one", {
  out <- tempfile(fileext = ".geojson")
  on.exit(unlink(out))

  osmium_export(fixture("denmark-mini.osm.pbf"), output = out)
  expect_true(file.exists(out))
  parsed <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  expect_equal(parsed$type, "FeatureCollection")
})

test_that("attributes adds requested OSM attributes to features", {
  text <- osmium_export(fixture("denmark-mini.osm.pbf"), output_format = "geojson",
                         attributes = "version,timestamp")
  parsed <- jsonlite::fromJSON(text, simplifyVector = FALSE)
  props <- parsed$features[[1]]$properties
  expect_true(any(grepl("@version|version", names(props))))
})

test_that("keep_untagged includes features without tags", {
  with_untagged <- osmium_export(fixture("denmark-mini.osm.pbf"), output_format = "geojson",
                                  keep_untagged = TRUE)
  without_untagged <- osmium_export(fixture("denmark-mini.osm.pbf"), output_format = "geojson")

  n_with <- length(jsonlite::fromJSON(with_untagged, simplifyVector = FALSE)$features)
  n_without <- length(jsonlite::fromJSON(without_untagged, simplifyVector = FALSE)$features)

  expect_gte(n_with, n_without)
})

test_that("output_format = pg produces WKB geometry + tag columns", {
  text <- osmium_export(fixture("denmark-mini.osm.pbf"), output_format = "pg")
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  lines <- lines[nzchar(lines)]
  expect_gt(length(lines), 0)

  # Each line is <tab-separated WKB hex><TAB><tag JSON>; the WKB hex
  # column starts with "01" (little-endian byte-order marker), which is
  # what osmium::geom::WKBFactory (osmium/geom/wkb.hpp) always emits.
  first_cols <- strsplit(lines[1], "\t", fixed = TRUE)[[1]]
  expect_true(startsWith(first_cols[1], "01"))
})

test_that("output_format = text produces WKT geometry + tag columns", {
  text <- osmium_export(fixture("denmark-mini.osm.pbf"), output_format = "text")
  lines <- strsplit(text, "\n", fixed = TRUE)[[1]]
  lines <- lines[nzchar(lines)]
  expect_gt(length(lines), 0)
  expect_true(grepl("^POINT\\(|^LINESTRING\\(|^POLYGON\\(", lines[1]))
})

test_that("index_type accepts anonymous-mmap-backed index types", {
  # sparse_mmap_array (and dense_mmap_array) are #ifdef __linux__-gated in
  # osmium/index/map/sparse_mmap_array.hpp itself -- growing an anonymous
  # mmap region relies on mremap(), which is Linux-only (no macOS/BSD
  # equivalent) -- so osmium::index::MapFactory genuinely never registers
  # this index type outside Linux, the same as real upstream osmium-tool.
  # Not something to fix in the vendored code; just skip where it doesn't
  # apply.
  skip_on_os(c("mac", "windows", "solaris"))

  out <- tempfile(fileext = ".geojson")
  on.exit(unlink(out))

  osmium_export(fixture("denmark-mini.osm.pbf"), output = out, index_type = "sparse_mmap_array")
  parsed <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  expect_equal(parsed$type, "FeatureCollection")
})

test_that("index_type accepts file-backed index types", {
  out <- tempfile(fileext = ".geojson")
  on.exit(unlink(out))

  # Unlike sparse_mmap_array (anonymous mmap) above, the *_file_array
  # index types back their storage with a real temp file (see
  # osmium/index/detail/{create_map_with_fd,mmap_vector_file,tmpfile}.hpp).
  osmium_export(fixture("denmark-mini.osm.pbf"), output = out, index_type = "sparse_file_array")
  parsed <- jsonlite::fromJSON(out, simplifyVector = FALSE)
  expect_equal(parsed$type, "FeatureCollection")
})

test_that("show_errors surfaces geometry problems instead of silently dropping them", {
  # A hand-crafted multipolygon relation with a way that has only one
  # node and a ring that never closes -- exercises
  # osmium::area::ProblemReporter (osmium/area/problem_reporter.hpp),
  # which nothing in the well-formed test fixture ever triggers.
  result <- rosmium:::rosmium_call(
    "export",
    c(fixture("broken-multipolygon.osm"), "--output-format", "geojson",
      "--show-errors", "-o", tempfile(fileext = ".geojson"))
  )
  expect_true(result$ok)
  expect_true(grepl("Geometry error", result$stderr, fixed = TRUE))
})
