# These tests compare rosmium's in-process output against the actual
# osmium-tool CLI binary, when one happens to be installed (never
# required -- CRAN/CI machines typically won't have it). CRC32 checksums
# (from `osmium fileinfo --crc`) are compared rather than raw bytes,
# since the two might be built from slightly different osmium-tool point
# releases and so emit different `generator=osmium/x.y.z` header/PBF
# metadata despite producing byte-identical OSM data.

test_that("osmium_getid matches the CLI's `osmium getid`", {
  skip_if_no_osmium_cli()
  out_cli <- tempfile(fileext = ".osm.pbf")
  out_r <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(out_cli, out_r)))

  system2("osmium", c("getid", "-r", "-t", fixture("denmark-mini.osm.pbf"),
                       mini_relation_id, "-o", out_cli))
  osmium_getid(fixture("denmark-mini.osm.pbf"), output = out_r, ids = mini_relation_id,
               add_referenced = TRUE, remove_tags = TRUE)

  expect_identical(
    osmium_fileinfo(out_cli, extended = TRUE, crc = TRUE)$data$crc32,
    osmium_fileinfo(out_r, extended = TRUE, crc = TRUE)$data$crc32
  )
})

test_that("osmium_extract(polygon=) matches the CLI's `osmium extract -p`", {
  skip_if_no_osmium_cli()
  poly <- tempfile(fileext = ".osm.pbf")
  out_cli <- tempfile(fileext = ".osm.pbf")
  out_r <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(poly, out_cli, out_r)))

  osmium_getid(fixture("denmark-mini.osm.pbf"), output = poly, ids = mini_relation_id,
               add_referenced = TRUE, remove_tags = TRUE)

  system2("osmium", c("extract", "-p", poly, fixture("denmark-mini.osm.pbf"), "-o", out_cli))
  osmium_extract(fixture("denmark-mini.osm.pbf"), output = out_r, polygon = poly)

  expect_identical(
    osmium_fileinfo(out_cli, extended = TRUE, crc = TRUE)$data$crc32,
    osmium_fileinfo(out_r, extended = TRUE, crc = TRUE)$data$crc32
  )
})

test_that("full extract -> tags-filter pipeline matches the CLI end to end", {
  skip_if_no_osmium_cli()

  cli_dir <- tempfile()
  r_dir <- tempfile()
  dir.create(cli_dir)
  dir.create(r_dir)
  on.exit(unlink(c(cli_dir, r_dir), recursive = TRUE))

  input <- fixture("denmark-mini.osm.pbf")
  box <- osmium_fileinfo(input, extended = TRUE)$data$bbox
  bbox_arg <- paste(box, collapse = ",")

  # -- ground truth: real osmium CLI -------------------------------------
  extract_cli <- file.path(cli_dir, "extract.pbf")
  highways_cli <- file.path(cli_dir, "highways.osm")
  system2("osmium", c("extract", "-b", bbox_arg, input, "-o", extract_cli))
  system2("osmium", c("tags-filter", extract_cli, "wr/highway", "-o", highways_cli))

  # -- rosmium -------------------------------------------------------------
  extract_r <- file.path(r_dir, "extract.pbf")
  highways_r <- file.path(r_dir, "highways.osm")
  osmium_extract(input, output = extract_r, bbox = box)
  osmium_tags_filter(extract_r, output = highways_r, expressions = "wr/highway")

  # This bbox is the fixture's own full extent, so the filtered result is
  # non-trivial (unlike, say, filtering within a single tiny building's
  # footprint) -- guard that assumption so a future fixture swap that
  # breaks it fails loudly instead of silently comparing two empty files.
  n_ways <- as.integer(osmium_fileinfo(highways_r, extended = TRUE, get = "data.count.ways"))
  expect_gt(n_ways, 0)

  expect_identical(
    osmium_fileinfo(highways_cli, extended = TRUE, crc = TRUE)$data$crc32,
    osmium_fileinfo(highways_r, extended = TRUE, crc = TRUE)$data$crc32
  )
})
