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

test_that("object_type = changeset filters out data objects from a data file", {
  out <- tempfile(fileext = ".opl")
  on.exit(unlink(out))

  # denmark-mini.osm.pbf is a data extract with no changesets, so this
  # exercises the entity-bit filtering path without any actual
  # changesets to find.
  osmium_cat(fixture("denmark-mini.osm.pbf"), output = out, object_type = "changeset", overwrite = TRUE)
  expect_equal(file.size(out), 0)
})

test_that("object_type = changeset reads real changeset data (osmium::Changeset)", {
  out <- tempfile(fileext = ".opl")
  on.exit(unlink(out))

  osmium_cat(fixture("changesets.osm"), output = out, object_type = "changeset")
  lines <- readLines(out, warn = FALSE)
  expect_length(lines, 2)
  expect_true(grepl("^c1 ", lines[1]))
  expect_true(grepl("utestuser", lines[1], fixed = TRUE))
  expect_true(grepl("^c2 ", lines[2]))
})

test_that("OPL round-trips as both an output and an input format", {
  opl_file <- tempfile(fileext = ".opl")
  back_file <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(opl_file, back_file)))

  osmium_cat(fixture("denmark-mini.osm.pbf"), output = opl_file)
  expect_true(file.size(opl_file) > 0)

  # input_format is auto-detected from the .opl extension here, the same
  # way the CLI would; reading OPL back in and writing to PBF exercises
  # OPL *input* parsing, which osmium_show()'s format = "opl" (output
  # only) does not.
  osmium_cat(opl_file, output = back_file)
  info <- osmium_fileinfo(back_file, extended = TRUE)
  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$count$ways, mini_counts$ways)
  expect_equal(info$data$count$relations, mini_counts$relations)
})

test_that("LZ4 PBF compression round-trips", {
  lz4_file <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(lz4_file))

  osmium_cat(fixture("denmark-mini.osm.pbf"), output = lz4_file, output_format = "pbf,pbf_compression=lz4")
  info <- osmium_fileinfo(lz4_file, extended = TRUE)
  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$count$ways, mini_counts$ways)
  expect_equal(info$data$count$relations, mini_counts$relations)
})
