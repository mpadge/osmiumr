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

test_that("osmium_fileinfo errors cleanly on a truncated/corrupt PBF", {
  # Reading through a truncated PBF (extended = TRUE forces a full read,
  # not just the header) exercises the malformed-input error paths in
  # protozero (protozero/exception.hpp) and libosmium's PBF decoder --
  # nothing in the well-formed test fixture ever triggers these, and
  # the point of the test is exactly that this surfaces as a normal R
  # error rather than crashing the session.
  corrupt <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(corrupt))
  raw <- readBin(fixture("denmark-mini.osm.pbf"), "raw", 2000)
  writeBin(raw, corrupt)

  expect_error(osmium_fileinfo(corrupt, extended = TRUE), "PBF")
})
