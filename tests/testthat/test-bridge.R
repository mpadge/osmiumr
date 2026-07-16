test_that("registered commands include all Phase 1 commands", {
  cmds <- rosmium_registered_commands()
  expect_true(all(c(
    "cat", "export", "extract", "fileinfo", "getid",
    "help", "merge", "sort", "tags-filter"
  ) %in% cmds))
})

test_that("unknown command raises an R error", {
  expect_error(rosmium_call("not-a-real-command", character()), "Unknown osmium command")
})

test_that("a bad argument raises an R error with the command name and details", {
  expect_error(
    osmium_fileinfo(fixture("denmark-mini.osm.pbf"), get = "not.a.real.variable"),
    "fileinfo"
  )
})

test_that("rosmium_call surfaces stdout/stderr text on request", {
  result <- rosmium_call("fileinfo", fixture("denmark-mini.osm.pbf"))
  expect_true(result$ok)
  expect_true(result$ran)
  expect_null(result$error)
  expect_true(nzchar(result$stdout))
})

test_that("the internal help command runs (command_help.cpp, no R wrapper)", {
  # "help" isn't exposed as an osmium_*() wrapper -- it's osmium-tool's
  # own top-level usage text, not something with parameters to build an
  # R function signature around -- but it's still registered and
  # reachable via the internal bridge, so cover it there.
  result <- rosmium_call("help", character())
  expect_true(result$ok)
  expect_true(nzchar(result$stdout))
  expect_true(grepl("COMMANDS", result$stdout, fixed = TRUE))

  topic_result <- rosmium_call("help", "fileinfo")
  expect_true(topic_result$ok)
})
