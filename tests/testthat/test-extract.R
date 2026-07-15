test_that("bbox extract keeps a subset of the data", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  full <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE)
  box <- full$data$bbox
  mid_lon <- mean(box[c(1, 3)])

  osmium_extract(fixture("denmark-mini.osm.pbf"), output = out,
                  bbox = c(box[1], box[2], mid_lon, box[4]))
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_lt(info$data$count$nodes, mini_counts$nodes)
  expect_gt(info$data$count$nodes, 0)
})

test_that("exactly one of bbox/polygon/config is required", {
  expect_error(
    osmium_extract(fixture("denmark-mini.osm.pbf"), output = tempfile()),
    "bbox"
  )
  expect_error(
    osmium_extract(fixture("denmark-mini.osm.pbf"), output = tempfile(),
                    bbox = c(12, 55, 13, 56), polygon = fixture("denmark-mini.osm.pbf")),
    "bbox"
  )
})

test_that("bbox must have length 4", {
  expect_error(
    osmium_extract(fixture("denmark-mini.osm.pbf"), output = tempfile(), bbox = c(12, 55)),
    "length 4"
  )
})

test_that("strategy argument is validated by match.arg", {
  expect_error(
    osmium_extract(fixture("denmark-mini.osm.pbf"), output = tempfile(),
                    bbox = c(12, 55, 13, 56), strategy = "not-a-strategy")
  )
})

test_that("set_bounds records a bounding box in the output header", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  full <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE)
  box <- full$data$bbox

  osmium_extract(fixture("denmark-mini.osm.pbf"), output = out, bbox = box, set_bounds = TRUE)
  info <- osmium_fileinfo(out)
  expect_gt(NROW(info$header$boxes), 0)
})

test_that("polygon accepts a .poly boundary file", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_extract(fixture("denmark-mini.osm.pbf"), output = out, polygon = fixture("boundary.poly"))
  info <- osmium_fileinfo(out, extended = TRUE)
  expect_gt(info$data$count$nodes, 0)
})

test_that("polygon accepts a GeoJSON boundary file", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_extract(fixture("denmark-mini.osm.pbf"), output = out, polygon = fixture("boundary.geojson"))
  info <- osmium_fileinfo(out, extended = TRUE)
  expect_gt(info$data$count$nodes, 0)
})

test_that("with_history runs without error", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  full <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE)
  box <- full$data$bbox

  osmium_extract(fixture("denmark-mini.osm.pbf"), output = out, bbox = box, with_history = TRUE)
  expect_true(file.exists(out))
})

test_that("strategy = smart produces a valid extract", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  full <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE)
  box <- full$data$bbox

  osmium_extract(fixture("denmark-mini.osm.pbf"), output = out, bbox = box, strategy = "smart")
  info <- osmium_fileinfo(out, extended = TRUE)
  expect_gt(info$data$count$nodes, 0)
})
