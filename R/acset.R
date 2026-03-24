# ACSet class and core operations -------------------------------------------

#' Attributed C-Set
#'
#' An ACSet is a mutable data structure implementing an attributed C-set
#' (a functor from a schema category to Set). It generalizes both graphs
#' and data frames.
#'
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
#' @export
nparts <- S7::new_generic("nparts", "x")

S7::method(nparts, ACSet) <- function(x, ob) {
  parts_nparts(x@.data$parts[[ob]])
}

#' Maximum part ID for an object type
#' @export
maxpart <- S7::new_generic("maxpart", "x")

S7::method(maxpart, ACSet) <- function(x, ob) {
  parts_maxpart(x@.data$parts[[ob]])
}

#' Get all part IDs for an object type
#' @export
parts <- S7::new_generic("parts", "x")

S7::method(parts, ACSet) <- function(x, ob) {
  parts_ids(x@.data$parts[[ob]])
}

#' Check if a part exists
#' @export
has_part <- S7::new_generic("has_part", "x")

S7::method(has_part, ACSet) <- function(x, ob, part) {
  parts_has(x@.data$parts[[ob]], part)
}

#' Check if a subpart (morphism/attribute) exists in the schema
#' @export
has_subpart <- S7::new_generic("has_subpart", "x")

S7::method(has_subpart, ACSet) <- function(x, f) {
  f %in% names(x@.data$subparts)
}

#' Add a single part, optionally setting subparts
#' @export
add_part <- S7::new_generic("add_part", "x")

S7::method(add_part, ACSet) <- function(x, ob, ...) {
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
  kwargs <- list(...)
  for (nm in names(kwargs)) {
    if (nm %in% names(x@.data$subparts)) {
      column_set(x@.data$subparts[[nm]], id, kwargs[[nm]])
    }
  }
  id
}

#' Add multiple parts at once
#' @export
add_parts <- S7::new_generic("add_parts", "x")

S7::method(add_parts, ACSet) <- function(x, ob, n, ...) {
  n <- as.integer(n)
  new_ids <- parts_add(x@.data$parts[[ob]], n)

  for (h in x@schema@homs) {
    if (h$dom == ob) column_grow(x@.data$subparts[[h$name]], n)
  }
  for (a in x@schema@attrs) {
    if (a$dom == ob) column_grow(x@.data$subparts[[a$name]], n)
  }

  kwargs <- list(...)
  for (nm in names(kwargs)) {
    if (nm %in% names(x@.data$subparts)) {
      vals <- kwargs[[nm]]
      column_set_multi(x@.data$subparts[[nm]], new_ids, vals)
    }
  }
  new_ids
}

#' Get subpart value(s)
#'
#' @param x An ACSet
#' @param part Integer part ID(s), or NULL for all parts of the domain object
#' @param f Character: morphism/attribute name, or character vector for composition
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
#' @export
set_subpart <- S7::new_generic("set_subpart", "x")

S7::method(set_subpart, ACSet) <- function(x, part, f, value) {
  if (length(part) == 1L && length(value) == 1L) {
    column_set(x@.data$subparts[[f]], part, value)
  } else {
    column_set_multi(x@.data$subparts[[f]], part, value)
  }
  invisible(x)
}

#' Set multiple subparts at once
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
#' @export
clear_subpart <- S7::new_generic("clear_subpart", "x")

S7::method(clear_subpart, ACSet) <- function(x, part, f) {
  for (i in part) {
    column_clear(x@.data$subparts[[f]], i)
  }
  invisible(x)
}

#' Incident query: find parts whose subpart equals a given value
#'
#' @param x An ACSet
#' @param value The value to look up
#' @param f Character: morphism/attribute name, or vector for composed path
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
