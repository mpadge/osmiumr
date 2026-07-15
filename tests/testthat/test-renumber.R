test_that("renumber assigns small consecutive IDs starting at 1", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_renumber(fixture("denmark-mini.osm.pbf"), output = out)
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$minid$nodes, 1)
  expect_equal(info$data$maxid$nodes, mini_counts$nodes)
})

test_that("start_id offsets the numbering", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_renumber(fixture("denmark-mini.osm.pbf"), output = out, start_id = "1000,1,1")
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_equal(info$data$minid$nodes, 1000)
  expect_equal(info$data$maxid$nodes, 999 + mini_counts$nodes)
})

test_that("object_type restricts what gets renumbered", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_renumber(fixture("denmark-mini.osm.pbf"), output = out, object_type = "node")
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_equal(info$data$minid$nodes, 1)
  # ways were left with their original (large, real-world) IDs
  expect_gt(info$data$minid$ways, mini_counts$ways)
})
