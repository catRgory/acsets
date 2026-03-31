# Package is loaded by tests/testthat.R via library(acsets)
library(testthat)
library(acsets)

# === Schema tests ==========================================================

test_that("BasicSchema validates correctly", {
  s <- BasicSchema(
    obs = c("V", "E"),
    homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
  )
  expect_s3_class(s, "S7_object")
  expect_equal(objects(s), c("V", "E"))
  expect_equal(length(homs(s)), 2)
  expect_equal(dom(s, "src"), "E")
  expect_equal(codom(s, "src"), "V")
})

test_that("BasicSchema with attrs validates", {
  s <- BasicSchema(
    obs = c("V", "E"),
    homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
    attrtypes = c("Name"),
    attrs = list(attr_spec("label", "V", "Name"))
  )
  expect_equal(attrtypes(s), "Name")
  expect_equal(length(attrs(s)), 1)
})

test_that("BasicSchema rejects invalid hom", {
  expect_error(BasicSchema(
    obs = "V",
    homs = list(hom("f", "E", "V"))
  ))
})

# === Parts tests ===========================================================

test_that("IntParts basic operations work", {
  p <- new_int_parts()
  expect_equal(parts_nparts(p), 0L)
  ids <- parts_add(p, 3L)
  expect_equal(ids, 1:3)
  expect_equal(parts_nparts(p), 3L)
  expect_equal(parts_ids(p), 1:3)
  expect_true(parts_has(p, 2L))
  expect_false(parts_has(p, 4L))
})

test_that("parts_add validates counts", {
  p <- new_int_parts()
  expect_equal(parts_add(p, 0L), integer(0))
  expect_equal(parts_nparts(p), 0L)
  expect_error(parts_add(p, -1L), "single non-negative integer")
})

# === Column tests ==========================================================

test_that("Unindexed column works", {
  col <- new_column(INDEX_NONE, 3L)
  column_set(col, 1L, 10L)
  column_set(col, 2L, 20L)
  column_set(col, 3L, 10L)
  expect_equal(column_get(col, 1L), 10L)
  expect_equal(column_get_multi(col, 1:2), c(10L, 20L))
  expect_equal(sort(column_preimage(col, 10L)), c(1L, 3L))
})

test_that("Indexed column works", {
  col <- new_column(INDEX_INDEXED, 3L)
  column_set(col, 1L, 10L)
  column_set(col, 2L, 20L)
  column_set(col, 3L, 10L)
  expect_equal(sort(column_preimage(col, 10L)), c(1L, 3L))
  expect_equal(column_preimage(col, 20L), 2L)
  expect_equal(column_preimage(col, 99L), integer(0))

  # Update value and check index
  column_set(col, 1L, 20L)
  expect_equal(column_preimage(col, 10L), 3L)
  expect_equal(sort(column_preimage(col, 20L)), c(1L, 2L))
})

test_that("Column clear works", {
  col <- new_column(INDEX_INDEXED, 2L)
  column_set(col, 1L, 5L)
  column_set(col, 2L, 5L)
  column_clear(col, 1L)
  expect_equal(column_preimage(col, 5L), 2L)
  expect_true(is.na(column_get(col, 1L)))
})

# === ACSet core tests ======================================================

SchGraph <- BasicSchema(
  obs = c("V", "E"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
)

test_that("ACSet construction and basic ops work", {
  g <- ACSet(SchGraph, index = c("src", "tgt"))
  expect_equal(nparts(g, "V"), 0L)

  add_parts(g, "V", 4L)
  expect_equal(nparts(g, "V"), 4L)

  add_parts(g, "E", 3L, src = c(1L, 2L, 3L), tgt = c(2L, 3L, 1L))
  expect_equal(nparts(g, "E"), 3L)
  expect_equal(subpart(g, 1L, "src"), 1L)
  expect_equal(subpart(g, 2L, "tgt"), 3L)
})

test_that("Subpart composition works", {
  g <- ACSet(SchGraph, index = c("src", "tgt"))
  add_parts(g, "V", 3L)
  add_parts(g, "E", 2L, src = c(1L, 2L), tgt = c(2L, 3L))
  expect_equal(subpart(g, 1L, c("src")), 1L)
})

test_that("Incident query works", {
  g <- ACSet(SchGraph, index = c("src", "tgt"))
  add_parts(g, "V", 3L)
  add_parts(g, "E", 3L, src = c(1L, 2L, 1L), tgt = c(2L, 3L, 3L))

  expect_equal(sort(incident(g, 1L, "src")), c(1L, 3L))
  expect_equal(incident(g, 3L, "tgt"), c(2L, 3L))
  expect_equal(incident(g, 99L, "src"), integer(0))
})

test_that("set_subpart and clear_subpart work", {
  g <- ACSet(SchGraph)
  add_parts(g, "V", 3L)
  add_part(g, "E")
  set_subpart(g, 1L, "src", 1L)
  set_subpart(g, 1L, "tgt", 2L)
  expect_equal(subpart(g, 1L, "src"), 1L)
  clear_subpart(g, 1L, "src")
  expect_true(is.na(subpart(g, 1L, "src")))
})

test_that("subpart writes enforce schema domains and references", {
  g <- ACSet(SchGraph)
  add_part(g, "V")
  expect_error(add_part(g, "V", src = 1L), "domain 'E'")
  expect_error(add_parts(g, "V", 2L, src = c(1L, 1L)), "domain 'E'")

  add_part(g, "E")
  expect_error(set_subpart(g, 2L, "src", 1L), "Part 2 of 'E' does not exist")
  expect_error(set_subpart(g, 1L, "src", 99L), "reference missing parts")
  expect_error(clear_subpart(g, 2L, "src"), "Part 2 of 'E' does not exist")
})

test_that("bulk subpart writes require compatible lengths", {
  sch <- BasicSchema(
    obs = c("V"),
    attrtypes = c("Name"),
    attrs = list(attr_spec("name", "V", "Name"))
  )
  g <- ACSet(sch)

  add_parts(g, "V", 4L, name = c("a", "b"))
  expect_equal(subpart(g, NULL, "name"), c("a", "b", "a", "b"))

  expect_error(
    add_parts(g, "V", 5L, name = c("x", "y")),
    "divide 5 exactly"
  )
  expect_error(
    set_subpart(g, c(1L, 2L, 3L), "name", c("u", "v")),
    "divide 3 exactly"
  )
})

# === Deletion tests ========================================================

test_that("rem_part with pop-and-swap works", {
  g <- ACSet(SchGraph, index = c("src", "tgt"))
  add_parts(g, "V", 3L)
  add_parts(g, "E", 3L, src = c(1L, 2L, 3L), tgt = c(2L, 3L, 1L))

  # Remove V=2: last V (3) replaces it; edges pointing to 2 are cleared
  rem_part(g, "V", 2L)
  expect_equal(nparts(g, "V"), 2L)
  # Edge 2 pointed to V=3, which is now V=2 after swap
  # Edge 3 src was V=3 → now V=2
  # Edge 1 tgt was V=2 → cleared
})

test_that("cascading_rem_part removes dependents", {
  g <- ACSet(SchGraph, index = c("src", "tgt"))
  add_parts(g, "V", 3L)
  add_parts(g, "E", 2L, src = c(1L, 2L), tgt = c(2L, 3L))

  cascading_rem_part(g, "V", 2L)
  # Both edges reference V=2, so both should be removed
  expect_equal(nparts(g, "E"), 0L)
})

# === Factory tests =========================================================

test_that("acset_type creates working constructor", {
  Graph <- acset_type(SchGraph, name = "Graph", index = c("src", "tgt"))
  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))
  expect_equal(nparts(g, "V"), 3L)
  expect_equal(nparts(g, "E"), 2L)
  expect_equal(subpart(g, 1L, "src"), 1L)
})

test_that("acset() works with constructor", {
  Graph <- acset_type(SchGraph, name = "Graph", index = c("src", "tgt"))
  g <- acset(Graph, V = 4, E = 3, src = c(1L,2L,3L), tgt = c(2L,3L,4L))
  expect_equal(nparts(g, "V"), 4L)
  expect_equal(subpart(g, 3L, "tgt"), 4L)
})

# === Copy and union tests ==================================================

test_that("copy_acset creates independent copy", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))
  g2 <- copy_acset(g)
  add_part(g2, "V")
  expect_equal(nparts(g, "V"), 3L)
  expect_equal(nparts(g2, "V"), 4L)
})

test_that("disjoint_union works", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g1 <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
  g2 <- Graph(V = 2, E = 1, src = 1L, tgt = 2L)
  gu <- disjoint_union(g1, g2)
  expect_equal(nparts(gu, "V"), 4L)
  expect_equal(nparts(gu, "E"), 2L)
  # Second edge should point to offset vertices
  expect_equal(subpart(gu, 2L, "src"), 3L)
  expect_equal(subpart(gu, 2L, "tgt"), 4L)
})

# === Query DSL tests =======================================================

test_that("From/Where/Select query works", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g <- Graph(V = 4, E = 4,
    src = c(1L,1L,2L,3L),
    tgt = c(2L,3L,3L,4L)
  )
  result <- From(g, "E") |> Where("src", `==`, 1L) |> Select("tgt")
  expect_equal(nrow(result), 2L)
  expect_equal(sort(result$tgt), c(2L, 3L))
})

# === JSON serialization tests ==============================================

test_that("JSON round-trip preserves data", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))

  json_list <- generate_json_acset(g)
  expect_equal(length(json_list$V), 3L)
  expect_equal(length(json_list$E), 2L)
  expect_equal(json_list$E[[1]]$src, 1L)

  g2 <- parse_json_acset(Graph, json_list)
  expect_true(acset_equal(g, g2))
})

test_that("JSON file round-trip works", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))
  tmp <- tempfile(fileext = ".json")
  write_json_acset(g, tmp)
  g2 <- read_json_acset(Graph, tmp)
  expect_true(acset_equal(g, g2))
  unlink(tmp)
})

# === Tables tests ==========================================================

test_that("as_data_frame works", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))
  df <- as_data_frame(g, "E")
  expect_equal(nrow(df), 2L)
  expect_equal(df$src, c(1L, 2L))
  expect_equal(df$tgt, c(2L, 3L))
})

test_that("tables returns all object tables", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))
  tbls <- tables(g)
  expect_true("V" %in% names(tbls))
  expect_true("E" %in% names(tbls))
  expect_equal(nrow(tbls$V), 3L)
})

# === Attributed ACSet tests ================================================

SchLabelledGraph <- BasicSchema(
  obs = c("V", "E"),
  homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
  attrtypes = c("Name"),
  attrs = list(attr_spec("label", "V", "Name"))
)

test_that("Attributed ACSet works", {
  LGraph <- acset_type(SchLabelledGraph, index = c("src", "tgt"))
  g <- LGraph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L),
              label = c("a", "b", "c"))
  expect_equal(subpart(g, 1L, "label"), "a")
  expect_equal(subpart(g, 3L, "label"), "c")
})

# === Print test ============================================================

test_that("ACSet prints without error", {
  Graph <- acset_type(SchGraph, index = c("src", "tgt"))
  g <- Graph(V = 3, E = 2, src = c(1L, 2L), tgt = c(2L, 3L))
  output <- format(g)
  expect_true(grepl("V: 3", output))
  expect_true(grepl("E: 2", output))
})

# === Petri net schema test (epicats-relevant) ==============================

SchLabelledPetriNet <- BasicSchema(
  obs = c("S", "T", "I", "O"),
  homs = list(
    hom("is", "I", "S"), hom("it", "I", "T"),
    hom("os", "O", "S"), hom("ot", "O", "T")
  ),
  attrtypes = c("Name"),
  attrs = list(
    attr_spec("sname", "S", "Name"),
    attr_spec("tname", "T", "Name")
  )
)

test_that("Petri net ACSet works (SIR model)", {
  LPN <- acset_type(SchLabelledPetriNet, index = c("is", "it", "os", "ot"))
  pn <- LPN()

  # Add species
  s_S <- add_part(pn, "S", sname = "S")
  s_I <- add_part(pn, "S", sname = "I")
  s_R <- add_part(pn, "S", sname = "R")

  # Add transitions
  t_inf <- add_part(pn, "T", tname = "inf")
  t_rec <- add_part(pn, "T", tname = "rec")

  # Infection: S + I -> 2I
  add_part(pn, "I", is = s_S, it = t_inf)
  add_part(pn, "I", is = s_I, it = t_inf)
  add_part(pn, "O", os = s_I, ot = t_inf)
  add_part(pn, "O", os = s_I, ot = t_inf)

  # Recovery: I -> R
  add_part(pn, "I", is = s_I, it = t_rec)
  add_part(pn, "O", os = s_R, ot = t_rec)

  expect_equal(nparts(pn, "S"), 3L)
  expect_equal(nparts(pn, "T"), 2L)
  expect_equal(nparts(pn, "I"), 3L)
  expect_equal(nparts(pn, "O"), 3L)

  # Check: inputs of infection transition
  inf_inputs <- incident(pn, t_inf, "it")
  expect_equal(length(inf_inputs), 2L)

  # Species names
  expect_equal(subpart(pn, s_S, "sname"), "S")
  expect_equal(subpart(pn, s_R, "sname"), "R")
})

cat("\nAll tests passed!\n")
