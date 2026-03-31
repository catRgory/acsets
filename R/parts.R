# Parts types ---------------------------------------------------------------
# Track how many parts (rows) each object has in an ACSet.
# Use plain environments for mutability (these live inside ACSet's .data env).
#
# IntParts: dense contiguous IDs 1:n (pop-and-swap deletion).
# BitSetParts: mark-as-deleted with gc compaction.

new_int_parts <- function(n = 0L) {
  env <- new.env(hash = FALSE, parent = emptyenv())
  env$n <- as.integer(n)
  env$type <- "int"
  env
}

new_bitset_parts <- function(n = 0L) {
  n <- as.integer(n)
  env <- new.env(hash = FALSE, parent = emptyenv())
  env$active <- rep(TRUE, n)
  env$next_id <- n + 1L
  env$type <- "bitset"
  env
}

parts_normalize_count <- function(n) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n != as.integer(n) || n < 0L) {
    cli::cli_abort("'n' must be a single non-negative integer.")
  }
  as.integer(n)
}

# Parts interface
parts_nparts <- function(p) {
  if (p$type == "int") p$n else sum(p$active)
}

parts_maxpart <- function(p) {
  if (p$type == "int") p$n else p$next_id - 1L
}

parts_ids <- function(p) {
  if (p$type == "int") seq_len(p$n) else which(p$active)
}

parts_has <- function(p, i) {
  if (p$type == "int") {
    i >= 1L && i <= p$n
  } else {
    i >= 1L && i <= length(p$active) && p$active[i]
  }
}

parts_add <- function(p, n = 1L) {
  n <- parts_normalize_count(n)
  if (n == 0L) {
    return(integer(0))
  }
  if (p$type == "int") {
    old <- p$n
    p$n <- old + n
    seq.int(old + 1L, old + n)
  } else {
    old_next <- p$next_id
    new_ids <- seq.int(old_next, old_next + n - 1L)
    p$active <- c(p$active, rep(TRUE, n))
    p$next_id <- old_next + n
    new_ids
  }
}
