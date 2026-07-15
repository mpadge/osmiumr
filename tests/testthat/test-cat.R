test_that("osmium_cat round-trips all data through PBF", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_cat(fixture("denmark-mini.osm.pbf"), output = out)
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$count$ways, mini_counts$ways)
  expect_equal(info$data$count$relations, mini_counts$relations)
})

test_that("object_type filters what osmium_cat writes", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_cat(fixture("denmark-mini.osm.pbf"), output = out, object_type = "node")
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$count$ways, 0)
  expect_equal(info$data$count$relations, 0)
})

test_that("clean strips requested attributes", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  # Before cleaning, the fixture has version and timestamp on all objects.
  before <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE)
  expect_true(before$data$metadata$all_objects$version)
  expect_true(before$data$metadata$all_objects$timestamp)

  osmium_cat(fixture("denmark-mini.osm.pbf"), output = out, clean = c("version", "timestamp"))
  after <- osmium_fileinfo(out, extended = TRUE)
  expect_false(after$data$metadata$all_objects$version)
  expect_false(after$data$metadata$all_objects$timestamp)
})

test_that("osmium_cat with output = NULL returns the data as text", {
  text <- osmium_cat(fixture("denmark-mini.osm.pbf"), output_format = "opl")
  expect_true(nzchar(text))
  expect_true(grepl(mini_highway_way_id, text, fixed = TRUE))
})

test_that("osmium_cat requires overwrite to replace an existing file", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))
  osmium_cat(fixture("denmark-mini.osm.pbf"), output = out)

  expect_error(osmium_cat(fixture("denmark-mini.osm.pbf"), output = out))
  expect_no_error(osmium_cat(fixture("denmark-mini.osm.pbf"), output = out, overwrite = TRUE))
})
