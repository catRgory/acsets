# ACSet class and core operations -------------------------------------------

#' Attributed C-Set
#'
#' An ACSet is a mutable data structure implementing an attributed C-set
#' (a functor from a schema category to Set). It generalizes both graphs
#' and data frames.
#'
#' @param schema A BasicSchema defining the structure.
#' @param index Character vector of morphism/attribute names to index.
#' @returns An ACSet S7 object.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("E", "V"),
#'   homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
#'   attrtypes = c("Name"),
#'   attrs = list(attr_spec("name", "V", "Name"))
#' )
#' g <- ACSet(sch)
#' add_parts(g, "V", 3, name = c("a", "b", "c"))
#' add_part(g, "E", src = 1L, tgt = 2L)
#' nparts(g, "V")
#' subpart(g, 1L, "name")
#' @rdname ACSet-class
#' @export
ACSet <- S7::new_class("ACSet",
  properties = list(
    schema = BasicSchema,
    .data = S7::new_property(class = S7::class_environment)
  ),
  constructor = function(schema, index = character()) {
    data_env <- new.env(hash = TRUE, parent = emptyenv())
    data_env$parts <- list()
    data_env$subparts <- list()
    data_env$index_config <- list()

    for (ob in schema@obs) {
      data_env$parts[[ob]] <- new_int_parts()
    }
    # Initialize hom columns
    for (h in schema@homs) {
      idx_type <- if (h$name %in% index) INDEX_INDEXED else INDEX_NONE
      data_env$subparts[[h$name]] <- new_column(idx_type)
      data_env$index_config[[h$name]] <- idx_type
    }
    # Initialize attr columns
    for (a in schema@attrs) {
      idx_type <- if (a$name %in% index) INDEX_INDEXED else INDEX_NONE
      data_env$subparts[[a$name]] <- new_attr_column(idx_type)
      data_env$index_config[[a$name]] <- idx_type
    }

    S7::new_object(S7::S7_object(), schema = schema, .data = data_env)
  }
)

# Core operations as S7 generics -------------------------------------------

#' Number of parts of a given object type
#'
#' @param x An ACSet.
#' @returns Integer count of parts.
#' @param ... Arguments passed to methods.
#' @examples
#' sch <- BasicSchema(obs = c("V"), homs = list())
#' g <- ACSet(sch)
#' add_parts(g, "V", 5)
#' nparts(g, "V")
#' @export
nparts <- S7::new_generic("nparts", "x")

S7::method(nparts, ACSet) <- function(x, ob) {
  parts_nparts(x@.data$parts[[ob]])
}

#' Maximum part ID for an object type
#'
#' @param x An ACSet.
#' @returns Integer maximum part ID.
#' @param ... Arguments passed to methods.
#' @export
maxpart <- S7::new_generic("maxpart", "x")

S7::method(maxpart, ACSet) <- function(x, ob) {
  parts_maxpart(x@.data$parts[[ob]])
}

#' Get all part IDs for an object type
#'
#' @param x An ACSet.
#' @returns Integer vector of part IDs.
#' @param ... Arguments passed to methods.
#' @export
parts <- S7::new_generic("parts", "x")

S7::method(parts, ACSet) <- function(x, ob) {
  parts_ids(x@.data$parts[[ob]])
}

#' Check if a part exists
#'
#' @param x An ACSet.
#' @returns Logical.
#' @param ... Arguments passed to methods.
#' @export
has_part <- S7::new_generic("has_part", "x")

S7::method(has_part, ACSet) <- function(x, ob, part) {
  parts_has(x@.data$parts[[ob]], part)
}

#' Check if a subpart (morphism/attribute) exists in the schema
#'
#' @param x An ACSet.
#' @returns Logical.
#' @param ... Arguments passed to methods.
#' @export
has_subpart <- S7::new_generic("has_subpart", "x")

S7::method(has_subpart, ACSet) <- function(x, f) {
  f %in% names(x@.data$subparts)
}

validate_acset_object <- function(x, ob) {
  if (!(ob %in% objects(x@schema))) {
    cli::cli_abort("Object '{ob}' not found in schema.")
  }
  ob
}

validate_subpart_name <- function(x, f) {
  if (!has_subpart(x, f)) {
    cli::cli_abort("Subpart '{f}' not found in schema.")
  }
  f
}

validate_part_ids <- function(part, what = "part IDs") {
  if (length(part) == 0L) {
    return(integer(0))
  }
  if (!is.numeric(part) || any(is.na(part)) || any(part != as.integer(part))) {
    cli::cli_abort("{what} must be integer part IDs.")
  }
  as.integer(part)
}

validate_existing_parts <- function(x, ob, part) {
  part <- validate_part_ids(part)
  missing <- part[!vapply(part, function(p) has_part(x, ob, p), logical(1))]
  if (length(missing) > 0L) {
    cli::cli_abort("Part {missing[[1L]]} of '{ob}' does not exist.")
  }
  part
}

validate_hom_values <- function(x, f, values, new_parts_for = NULL, new_part_count = 0L) {
  if (!schema_is_hom(x@schema, f) || length(values) == 0L) {
    return(values)
  }

  non_missing <- !is.na(values)
  if (!any(non_missing)) {
    return(values)
  }

  refs <- values[non_missing]
  if (!is.numeric(refs) || any(refs != as.integer(refs))) {
    cli::cli_abort("Values for hom '{f}' must be integer part IDs or NA.")
  }

  refs <- as.integer(refs)
  codom_ob <- codom(x@schema, f)
  max_allowed <- nparts(x, codom_ob)
  if (!is.null(new_parts_for) && identical(codom_ob, new_parts_for)) {
    max_allowed <- max_allowed + new_part_count
  }

  bad <- refs[refs < 1L | refs > max_allowed]
  if (length(bad) > 0L) {
    cli::cli_abort("Values for hom '{f}' reference missing parts of '{codom_ob}'.")
  }

  values[non_missing] <- refs
  values
}

prepare_new_subpart_values <- function(x, ob, kwargs, n) {
  schema <- x@schema
  lapply(names(kwargs), function(nm) {
    validate_subpart_name(x, nm)
    expected_ob <- dom(schema, nm)
    if (!identical(expected_ob, ob)) {
      cli::cli_abort("Subpart '{nm}' has domain '{expected_ob}', not '{ob}'.")
    }
    values <- column_normalize_values(kwargs[[nm]], n, "Subpart values")
    validate_hom_values(x, nm, values, new_parts_for = ob, new_part_count = n)
  }) |> stats::setNames(names(kwargs))
}

prepare_existing_subpart_values <- function(x, part, f, value) {
  validate_subpart_name(x, f)
  ob <- dom(x@schema, f)
  part <- validate_existing_parts(x, ob, part)
  value <- column_normalize_values(value, length(part), "Subpart values")
  value <- validate_hom_values(x, f, value)
  list(ob = ob, part = part, value = value)
}

#' Add a single part, optionally setting subparts
#'
#' @param x An ACSet.
#' @returns Integer ID of the newly added part.
#' @param ... Named subpart values to set on the new part.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("E", "V"),
#'   homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
#' )
#' g <- ACSet(sch)
#' add_part(g, "V")
#' add_part(g, "V")
#' add_part(g, "E", src = 1L, tgt = 2L)
#' subpart(g, 1L, "src")
#' @export
add_part <- S7::new_generic("add_part", "x")

S7::method(add_part, ACSet) <- function(x, ob, ...) {
  ob <- validate_acset_object(x, ob)
  kwargs <- prepare_new_subpart_values(x, ob, list(...), 1L)
  new_ids <- parts_add(x@.data$parts[[ob]], 1L)
  id <- new_ids[1L]

  # Grow all columns for this object
  for (h in x@schema@homs) {
    if (h$dom == ob) column_grow(x@.data$subparts[[h$name]], 1L)
  }
  for (a in x@schema@attrs) {
    if (a$dom == ob) column_grow(x@.data$subparts[[a$name]], 1L)
  }

  # Set any provided subpart values
  for (nm in names(kwargs)) {
    column_set(x@.data$subparts[[nm]], id, kwargs[[nm]])
  }
  id
}

#' Add multiple parts at once
#'
#' @param x An ACSet.
#' @returns Integer vector of newly added part IDs.
#' @param ... Named subpart values. Vectors must have length 1, length `n`, or
#'   recycle evenly across `n`.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("V"),
#'   attrtypes = c("Name"),
#'   attrs = list(attr_spec("name", "V", "Name"))
#' )
#' g <- ACSet(sch)
#' ids <- add_parts(g, "V", 3, name = c("a", "b", "c"))
#' ids
#' subpart(g, NULL, "name")
#' @export
add_parts <- S7::new_generic("add_parts", "x")

S7::method(add_parts, ACSet) <- function(x, ob, n, ...) {
  ob <- validate_acset_object(x, ob)
  n <- parts_normalize_count(n)
  kwargs <- prepare_new_subpart_values(x, ob, list(...), n)
  new_ids <- parts_add(x@.data$parts[[ob]], n)

  for (h in x@schema@homs) {
    if (h$dom == ob) column_grow(x@.data$subparts[[h$name]], n)
  }
  for (a in x@schema@attrs) {
    if (a$dom == ob) column_grow(x@.data$subparts[[a$name]], n)
  }

  for (nm in names(kwargs)) {
    column_set_multi(x@.data$subparts[[nm]], new_ids, kwargs[[nm]])
  }
  new_ids
}

#' Get subpart value(s)
#'
#' @param x An ACSet
#' @param ... Arguments passed to methods.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("E", "V"),
#'   homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
#'   attrtypes = c("Name"),
#'   attrs = list(attr_spec("name", "V", "Name"))
#' )
#' g <- ACSet(sch)
#' add_parts(g, "V", 3, name = c("a", "b", "c"))
#' add_part(g, "E", src = 1L, tgt = 2L)
#' # Single value
#' subpart(g, 1L, "src")
#' # All values
#' subpart(g, NULL, "name")
#' # Composed path: source vertex name of edge 1
#' subpart(g, 1L, c("src", "name"))
#' @export
subpart <- S7::new_generic("subpart", "x")

S7::method(subpart, ACSet) <- function(x, part, f) {
  if (length(f) > 1L) {
    # Composed path: follow morphisms sequentially
    result <- part
    for (fi in f) {
      result <- column_get_multi(x@.data$subparts[[fi]], result)
    }
    return(result)
  }
  if (is.null(part)) {
    # All parts of the domain object
    ob <- dom(x@schema, f)
    part <- parts(x, ob)
  }
  if (length(part) == 1L) {
    column_get(x@.data$subparts[[f]], part)
  } else {
    column_get_multi(x@.data$subparts[[f]], part)
  }
}

#' Set a single subpart value
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
set_subpart <- S7::new_generic("set_subpart", "x")

S7::method(set_subpart, ACSet) <- function(x, part, f, value) {
  prepared <- prepare_existing_subpart_values(x, part, f, value)
  if (length(prepared$part) == 1L && length(prepared$value) == 1L) {
    column_set(x@.data$subparts[[f]], prepared$part, prepared$value)
  } else {
    column_set_multi(x@.data$subparts[[f]], prepared$part, prepared$value)
  }
  invisible(x)
}

#' Set multiple subparts at once
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
set_subparts <- S7::new_generic("set_subparts", "x")

S7::method(set_subparts, ACSet) <- function(x, part, ...) {
  kwargs <- list(...)
  for (nm in names(kwargs)) {
    set_subpart(x, part, nm, kwargs[[nm]])
  }
  invisible(x)
}

#' Clear a subpart value
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
clear_subpart <- S7::new_generic("clear_subpart", "x")

S7::method(clear_subpart, ACSet) <- function(x, part, f) {
  validate_subpart_name(x, f)
  ob <- dom(x@schema, f)
  for (i in validate_existing_parts(x, ob, part)) {
    column_clear(x@.data$subparts[[f]], i)
  }
  invisible(x)
}

#' Incident query: find parts whose subpart equals a given value
#'
#' @param x An ACSet
#' @param ... Arguments passed to methods.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("E", "V"),
#'   homs = list(hom("src", "E", "V"), hom("tgt", "E", "V"))
#' )
#' g <- ACSet(sch, index = c("src", "tgt"))
#' add_parts(g, "V", 3)
#' add_parts(g, "E", 2, src = c(1L, 1L), tgt = c(2L, 3L))
#' # Which edges have source vertex 1?
#' incident(g, 1L, "src")
#' @export
incident <- S7::new_generic("incident", "x")

S7::method(incident, ACSet) <- function(x, value, f) {
  if (length(f) > 1L) {
    # Composed incident: work backwards through the path
    result <- value
    for (fi in rev(f)) {
      result <- unlist(lapply(result, function(v) column_preimage(x@.data$subparts[[fi]], v)))
    }
    return(as.integer(unique(result)))
  }
  column_preimage(x@.data$subparts[[f]], value)
}

# Print method
S7::method(format, ACSet) <- function(x, ...) {
  lines <- character()
  obs <- objects(x@schema)
  parts_info <- vapply(obs, function(ob) {
    sprintf("%s: %d", ob, nparts(x, ob))
  }, character(1))
  lines <- c(lines, sprintf("ACSet (%s)", paste(parts_info, collapse = ", ")))

  for (ob in obs) {
    n <- nparts(x, ob)
    if (n == 0L) next
    ob_homs <- homs(x@schema, from = ob)
    ob_attrs <- attrs(x@schema, from = ob)
    if (length(ob_homs) + length(ob_attrs) == 0L) next

    ids <- parts(x, ob)
    display_n <- min(n, 6L)
    display_ids <- ids[seq_len(display_n)]

    cols <- list()
    for (h in ob_homs) {
      cols[[h$name]] <- column_get_multi(x@.data$subparts[[h$name]], display_ids)
    }
    for (a in ob_attrs) {
      vals <- column_get_multi(x@.data$subparts[[a$name]], display_ids)
      cols[[a$name]] <- vals
    }
    if (length(cols) > 0L) {
      col_strs <- vapply(names(cols), function(cn) {
        sprintf("  %s = [%s%s]", cn,
                paste(head(cols[[cn]], 6), collapse = ", "),
                if (n > 6L) ", ..." else "")
      }, character(1))
      lines <- c(lines, col_strs)
    }
  }
  paste(lines, collapse = "\n")
}
