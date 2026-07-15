test_that("sort preserves object counts", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_sort(fixture("denmark-mini.osm.pbf"), output = out)
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_equal(info$data$count$nodes, mini_counts$nodes)
  expect_equal(info$data$count$ways, mini_counts$ways)
  expect_equal(info$data$count$relations, mini_counts$relations)
  expect_true(info$data$objects_ordered)
})

test_that("sort accepts multiple input files", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_sort(c(fixture("denmark-mini.osm.pbf"), fixture("denmark-mini.osm.pbf")), output = out)
  info <- osmium_fileinfo(out, extended = TRUE)

  # Sorting the same file with itself duplicates every object (each ID
  # appears twice, consecutively, once sorted) rather than erroring.
  expect_equal(info$data$count$nodes, mini_counts$nodes * 2)
})

test_that("multipass strategy produces the same result as simple", {
  out_simple <- tempfile(fileext = ".osm.pbf")
  out_multipass <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(out_simple, out_multipass)))

  osmium_sort(fixture("denmark-mini.osm.pbf"), output = out_simple, strategy = "simple")
  osmium_sort(fixture("denmark-mini.osm.pbf"), output = out_multipass, strategy = "multipass")

  expect_identical(
    osmium_fileinfo(out_simple, extended = TRUE, crc = TRUE)$data$crc32,
    osmium_fileinfo(out_multipass, extended = TRUE, crc = TRUE)$data$crc32
  )
})
