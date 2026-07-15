test_that("tags-filter keeps only matching objects (plus referenced)", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = out, expressions = "wr/highway")
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_lte(info$data$count$ways, mini_counts$ways)
  expect_gt(info$data$count$ways, 0)
  expect_gt(info$data$count$nodes, 0) # referenced way nodes are pulled in
})

test_that("omit_referenced drops nodes that are only referenced", {
  out_with_refs <- tempfile(fileext = ".osm.pbf")
  out_without_refs <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(out_with_refs, out_without_refs)))

  osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = out_with_refs, expressions = "w/highway")
  osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = out_without_refs,
                      expressions = "w/highway", omit_referenced = TRUE)

  # `get=` sidesteps computing/serializing a bounding box, which is what
  # `extended = TRUE` alone would do and which errors on a file with no
  # located nodes -- true of out_without_refs here, and true of real
  # osmium-tool's own `fileinfo --extended --json`, not an osmiumr bug.
  n_with_refs <- as.integer(osmium_fileinfo(out_with_refs, extended = TRUE, get = "data.count.nodes"))
  n_without_refs <- as.integer(osmium_fileinfo(out_without_refs, extended = TRUE, get = "data.count.nodes"))

  expect_gt(n_with_refs, n_without_refs)
  expect_equal(n_without_refs, 0)
})

test_that("invert_match keeps the complementary set", {
  matching <- tempfile(fileext = ".osm.pbf")
  inverted <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(matching, inverted)))

  osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = matching,
                      expressions = "w/highway", omit_referenced = TRUE)
  osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = inverted,
                      expressions = "w/highway", omit_referenced = TRUE, invert_match = TRUE)

  n_matching <- as.integer(osmium_fileinfo(matching, extended = TRUE, get = "data.count.ways"))
  n_inverted <- as.integer(osmium_fileinfo(inverted, extended = TRUE, get = "data.count.ways"))

  expect_equal(n_matching + n_inverted, mini_counts$ways)
})

test_that("expressions_file works the same as an inline expression", {
  expr_file <- tempfile()
  writeLines("wr/highway", expr_file)
  on.exit(unlink(expr_file))

  out_inline <- tempfile(fileext = ".osm.pbf")
  out_file <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(out_inline, out_file)), add = TRUE)

  osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = out_inline, expressions = "wr/highway")
  osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = out_file, expressions_file = expr_file)

  expect_identical(
    osmium_fileinfo(out_inline, extended = TRUE, crc = TRUE)$data$crc32,
    osmium_fileinfo(out_file, extended = TRUE, crc = TRUE)$data$crc32
  )
})

test_that("requires expressions or expressions_file", {
  expect_error(
    osmium_tags_filter(fixture("denmark-mini.osm.pbf"), output = tempfile()),
    "expressions"
  )
})
