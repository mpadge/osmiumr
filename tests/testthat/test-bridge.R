test_that("registered commands include all Phase 1 commands", {
  cmds <- osmiumr_registered_commands()
  expect_true(all(c(
    "cat", "check-refs", "export", "extract", "fileinfo", "getid",
    "help", "merge", "renumber", "show", "sort", "tags-filter"
  ) %in% cmds))
})

test_that("unknown command raises an R error", {
  expect_error(osmiumr_call("not-a-real-command", character()), "Unknown osmium command")
})

test_that("a bad argument raises an R error with the command name and details", {
  expect_error(
    osmium_fileinfo(fixture("denmark-mini.osm.pbf"), get = "not.a.real.variable"),
    "fileinfo"
  )
})

test_that("osmiumr_call surfaces stdout/stderr text on request", {
  result <- osmiumr_call("fileinfo", fixture("denmark-mini.osm.pbf"))
  expect_true(result$ok)
  expect_true(result$ran)
  expect_null(result$error)
  expect_true(nzchar(result$stdout))
})
