test_that("osmium_show returns formatted text containing known content", {
  text <- osmium_show(fixture("denmark-mini.osm.pbf"), format = "opl")
  expect_true(grepl(mini_highway_way_id, text, fixed = TRUE))
  expect_true(grepl(mini_relation_id, text, fixed = TRUE))
})

test_that("object_type restricts what osmium_show prints", {
  text <- osmium_show(fixture("denmark-mini.osm.pbf"), format = "opl", object_type = "node")
  expect_false(grepl(mini_highway_way_id, text, fixed = TRUE))
  expect_false(grepl(mini_relation_id, text, fixed = TRUE))
  expect_true(grepl("^n", text))
})

test_that("format argument selects the output format", {
  xml_text <- osmium_show(fixture("denmark-mini.osm.pbf"), format = "xml")
  expect_true(grepl("<osm", xml_text, fixed = TRUE))
})
