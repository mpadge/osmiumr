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
