test_that("osmium_getid extracts the requested relation", {
  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out))

  osmium_getid(fixture("denmark-mini.osm.pbf"), output = out, ids = mini_relation_id,
               add_referenced = TRUE, remove_tags = TRUE)
  info <- osmium_fileinfo(out, extended = TRUE)

  expect_equal(info$data$count$relations, 1)
  expect_gt(info$data$count$ways, 0) # add_referenced pulls in member ways
})

test_that("default_type applies to unprefixed IDs", {
  out_prefixed <- tempfile(fileext = ".osm.pbf")
  out_default <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(out_prefixed, out_default)))

  osmium_getid(fixture("denmark-mini.osm.pbf"), output = out_prefixed, ids = mini_relation_id)
  osmium_getid(fixture("denmark-mini.osm.pbf"), output = out_default,
               ids = sub("^r", "", mini_relation_id), default_type = "relation")

  # Both outputs contain nothing but the bare relation (no add_referenced),
  # so they're expected to be byte-identical -- and since both come from
  # the same osmiumr build, comparing bytes directly (rather than via
  # `osmium_fileinfo(extended = TRUE)`, whose bbox/CRC computation errors
  # on files with no located nodes, matching real osmium-tool's own
  # behaviour) is both simpler and unaffected by that.
  expect_identical(
    unname(tools::md5sum(out_prefixed)),
    unname(tools::md5sum(out_default))
  )
})

test_that("id_file works as an alternative to ids", {
  id_file <- tempfile()
  writeLines(mini_relation_id, id_file)
  on.exit(unlink(id_file))

  out <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(out), add = TRUE)

  osmium_getid(fixture("denmark-mini.osm.pbf"), output = out, id_file = id_file)
  n <- osmium_fileinfo(out, extended = TRUE, get = "data.count.relations")
  expect_identical(n, "1")
})

test_that("requires at least one of ids/id_file/id_osm_file", {
  expect_error(
    osmium_getid(fixture("denmark-mini.osm.pbf"), output = tempfile()),
    "ids"
  )
})
