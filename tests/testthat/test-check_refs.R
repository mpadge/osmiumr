test_that("osmium_check_refs runs and returns a structured result", {
  result <- osmium_check_refs(fixture("denmark-mini.osm.pbf"))
  expect_type(result$ok, "logical")
  expect_type(result$missing_ids, "character")
  expect_true(nzchar(result$details))
})

test_that("show_ids populates missing_ids only when there are missing refs", {
  result <- osmium_check_refs(fixture("denmark-mini.osm.pbf"), show_ids = TRUE)
  if (result$ok) {
    expect_length(result$missing_ids, 0)
  } else {
    expect_gt(length(result$missing_ids), 0)
    expect_true(all(grepl("^[nwr][0-9]+ in [nwr][0-9]+$", result$missing_ids)))
  }
})

test_that("check_relations runs the broader relation-aware check", {
  with_rel <- osmium_check_refs(fixture("denmark-mini.osm.pbf"), check_relations = TRUE)
  expect_type(with_rel$ok, "logical")
  # Every "node/way missing" problem found without check_relations is a
  # subset of what check_relations = TRUE can find, so ok can only get
  # worse (or stay the same), never better, by turning it on.
  without_rel <- osmium_check_refs(fixture("denmark-mini.osm.pbf"), check_relations = FALSE)
  expect_true(without_rel$ok || !with_rel$ok)
})
