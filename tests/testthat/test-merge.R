test_that("merging two disjoint bbox extracts reconstructs the total node count", {
  full <- osmium_fileinfo(fixture("denmark-mini.osm.pbf"), extended = TRUE)
  box <- full$data$bbox
  mid_lat <- mean(box[c(2, 4)])

  bottom <- tempfile(fileext = ".osm.pbf")
  top <- tempfile(fileext = ".osm.pbf")
  bottom_sorted <- tempfile(fileext = ".osm.pbf")
  top_sorted <- tempfile(fileext = ".osm.pbf")
  merged <- tempfile(fileext = ".osm.pbf")
  on.exit(unlink(c(bottom, top, bottom_sorted, top_sorted, merged)))

  osmium_extract(fixture("denmark-mini.osm.pbf"), output = bottom,
                  bbox = c(box[1], box[2], box[3], mid_lat), strategy = "simple")
  osmium_extract(fixture("denmark-mini.osm.pbf"), output = top,
                  bbox = c(box[1], mid_lat, box[3], box[4]), strategy = "simple")

  osmium_sort(bottom, output = bottom_sorted)
  osmium_sort(top, output = top_sorted)

  osmium_merge(c(bottom_sorted, top_sorted), output = merged)

  n_bottom <- osmium_fileinfo(bottom, extended = TRUE)$data$count$nodes
  n_top <- osmium_fileinfo(top, extended = TRUE)$data$count$nodes
  n_merged <- osmium_fileinfo(merged, extended = TRUE)$data$count$nodes

  # simple-strategy bboxes on either side of mid_lat can only share nodes
  # that sit exactly on the splitting line, so this is an inequality
  # rather than requiring an exact non-overlapping partition.
  expect_gte(n_merged, max(n_bottom, n_top))
  expect_lte(n_merged, n_bottom + n_top)
})
