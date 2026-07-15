test_that("osmium_fileinfo returns basic file/header info without extended", {
  info <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"))
  expect_equal(info$file$format, "PBF")
  expect_null(info$data)
})

test_that("osmium_fileinfo(extended = TRUE) matches known counts", {
  info <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE)
  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$count$ways, mini_counts$ways)
  expect_equal(info$data$count$relations, mini_counts$relations)
})

test_that("osmium_fileinfo(crc = TRUE) reports a CRC32 checksum", {
  info <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE, crc = TRUE)
  expect_true(nzchar(info$data$crc32))
})

test_that("osmium_fileinfo(get=) returns a single value", {
  n <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE, get = "data.count.nodes")
  expect_identical(n, as.character(mini_counts$nodes))

  fmt <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), get = "file.format")
  expect_identical(fmt, "PBF")
})

test_that("object_type restricts extended counts", {
  info <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE, object_type = "node")
  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$count$ways, 0)
  expect_equal(info$data$count$relations, 0)
})

test_that("osmium_fileinfo errors on a nonexistent file", {
  expect_error(osmium_fileinfo("/no/such/file.osm.pbf"))
})
