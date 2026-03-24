# ACSet type factory and NSE constructor ------------------------------------

#' Create an ACSet type bound to a specific schema
#'
#' Returns a constructor function that creates ACSets with the given schema.
#' This is the R equivalent of Julia's `@acset_type`.
#'
#' @param schema A BasicSchema
#' @param name Optional name for the type
#' @param index Character vector of morphism/attribute names to index
#' @returns A function that creates ACSet instances with this schema
#' @export
acset_type <- function(schema, name = NULL, index = character()) {
  force(schema)
  force(index)
  constructor <- function(...) {
    acs <- ACSet(schema, index = index)
    kwargs <- list(...)
    if (length(kwargs) > 0L) {
      populate_acset(acs, kwargs)
    }
    acs
  }
  if (!is.null(name)) {
    attr(constructor, "acset_type_name") <- name
  }
  attr(constructor, "schema") <- schema
  attr(constructor, "index") <- index
  class(constructor) <- c("acset_constructor", "function")
  constructor
}

# Populate an ACSet from a named list of values
populate_acset <- function(acs, kwargs) {
  schema <- acs@schema

  # First pass: add parts for each object
  for (ob in schema@obs) {
    if (ob %in% names(kwargs)) {
      n <- kwargs[[ob]]
      if (is.numeric(n) && length(n) == 1L) {
        add_parts(acs, ob, as.integer(n))
      }
    }
  }

  # Second pass: set subpart values
  arrow_names <- schema_arrow_names(schema)
  for (nm in names(kwargs)) {
    if (nm %in% arrow_names) {
      vals <- kwargs[[nm]]
      ob <- dom(schema, nm)
      all_ids <- parts(acs, ob)
      set_subpart(acs, all_ids, nm, vals)
    }
  }
  acs
}

#' Construct an ACSet using named arguments or NSE
#'
#' @param type An acset_constructor (from acset_type()) or an ACSet class
#' @param ... Named arguments: object names get integer counts,
#'   morphism/attribute names get value vectors
#' @returns An ACSet instance
#' @export
acset <- function(type, ...) {
  if (inherits(type, "acset_constructor")) {
    type(...)
  } else {
    cli::cli_abort("'type' must be an acset_constructor from acset_type()")
  }
}

# Copy and disjoint union --------------------------------------------------

#' Create a deep copy of an ACSet
#' @keywords internal
copy_acset <- function(x) {
  acs <- ACSet(x@schema, index = names(which(
    vapply(x@.data$index_config, function(ic) ic != INDEX_NONE, logical(1))
  )))
  for (ob in objects(x@schema)) {
    n <- nparts(x, ob)
    if (n > 0L) add_parts(acs, ob, n)
  }
  for (nm in names(x@.data$subparts)) {
    src_col <- x@.data$subparts[[nm]]
    defined <- which(src_col$defined)
    if (length(defined) > 0L) {
      set_subpart(acs, defined, nm, src_col$values[defined])
    }
  }
  acs
}

#' Disjoint union of two ACSets with the same schema
#' @export
disjoint_union <- S7::new_generic("disjoint_union", "x")

S7::method(disjoint_union, ACSet) <- function(x, y) {
  stopifnot(identical(x@schema, y@schema))
  result <- copy_acset(x)
  schema <- x@schema

  # Track ID offsets for each object in x
  offsets <- list()
  for (ob in schema@obs) {
    offsets[[ob]] <- nparts(result, ob)
  }

  # Add all parts from y
  for (ob in schema@obs) {
    n_y <- nparts(y, ob)
    if (n_y > 0L) add_parts(result, ob, n_y)
  }

  # Copy hom values from y with offset
  for (h in schema@homs) {
    y_ids <- parts(y, h$dom)
    if (length(y_ids) == 0L) next
    vals <- subpart(y, y_ids, h$name)
    defined <- !is.na(vals)
    if (any(defined)) {
      new_ids <- y_ids + offsets[[h$dom]]
      new_vals <- vals
      new_vals[defined] <- vals[defined] + offsets[[h$codom]]
      set_subpart(result, new_ids[defined], h$name, new_vals[defined])
    }
  }

  # Copy attr values from y (no offset)
  for (a in schema@attrs) {
    y_ids <- parts(y, a$dom)
    if (length(y_ids) == 0L) next
    vals <- subpart(y, y_ids, a$name)
    defined <- !is.na(vals)
    if (any(defined)) {
      new_ids <- y_ids + offsets[[a$dom]]
      set_subpart(result, new_ids[defined], a$name, vals[defined])
    }
  }

  result
}
