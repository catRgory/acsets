# BasicSchema ---------------------------------------------------------------
# Port of ACSets.jl BasicSchema: defines the shape of an ACSet.

#' ACSet Schema
#'
#' A schema describes the structure of an ACSet: its objects (tables),
#' morphisms (foreign keys), attribute types, and attributes.
#'
#' @param obs Character vector of object names.
#' @param homs List of morphisms, each a named list with `name`, `dom`, `codom`
#'   (all character strings referring to elements of `obs`).
#' @param attrtypes Character vector of attribute type names.
#' @param attrs List of attributes, each a named list with `name`, `dom`
#'   (an object name), `codom` (an attribute type name).
#' @returns A `BasicSchema` S7 object.
#' @export
BasicSchema <- S7::new_class("BasicSchema",
  properties = list(
    obs = S7::class_character,
    homs = S7::class_list,
    attrtypes = S7::class_character,
    attrs = S7::class_list
  ),
  validator = function(self) {
    errors <- character()
    # Validate homs
    for (i in seq_along(self@homs)) {
      h <- self@homs[[i]]
      if (!is.list(h) || !all(c("name", "dom", "codom") %in% names(h))) {
        errors <- c(errors, sprintf("homs[[%d]] must have 'name', 'dom', 'codom'", i))
        next
      }
      if (!h$dom %in% self@obs) {
        errors <- c(errors, sprintf("hom '%s' domain '%s' not in obs", h$name, h$dom))
      }
      if (!h$codom %in% self@obs) {
        errors <- c(errors, sprintf("hom '%s' codomain '%s' not in obs", h$name, h$codom))
      }
    }
    # Validate attrs
    for (i in seq_along(self@attrs)) {
      a <- self@attrs[[i]]
      if (!is.list(a) || !all(c("name", "dom", "codom") %in% names(a))) {
        errors <- c(errors, sprintf("attrs[[%d]] must have 'name', 'dom', 'codom'", i))
        next
      }
      if (!a$dom %in% self@obs) {
        errors <- c(errors, sprintf("attr '%s' domain '%s' not in obs", a$name, a$dom))
      }
      if (!a$codom %in% self@attrtypes) {
        errors <- c(errors, sprintf("attr '%s' codomain '%s' not in attrtypes", a$name, a$codom))
      }
    }
    # Check for duplicate names
    all_arrow_names <- c(
      vapply(self@homs, function(h) h$name, character(1)),
      vapply(self@attrs, function(a) a$name, character(1))
    )
    dupes <- all_arrow_names[duplicated(all_arrow_names)]
    if (length(dupes) > 0) {
      errors <- c(errors, sprintf("duplicate arrow names: %s", paste(dupes, collapse = ", ")))
    }
    if (length(errors) > 0) errors else NULL
  }
)

# Convenience constructor for hom/attr specs
#' @keywords internal
hom <- function(name, dom, codom) {
  list(name = name, dom = dom, codom = codom)
}

#' @keywords internal
attr_spec <- function(name, dom, codom) {
  list(name = name, dom = dom, codom = codom)
}

# Schema query functions ----------------------------------------------------

#' @export
objects <- S7::new_generic("objects", "x")

S7::method(objects, BasicSchema) <- function(x) {
  x@obs
}

#' @export
homs <- S7::new_generic("homs", "x")

S7::method(homs, BasicSchema) <- function(x, from = NULL, to = NULL) {
  result <- x@homs
  if (!is.null(from)) {
    result <- Filter(function(h) h$dom == from, result)
  }
  if (!is.null(to)) {
    result <- Filter(function(h) h$codom == to, result)
  }
  result
}

#' @export
attrs <- S7::new_generic("attrs", "x")

S7::method(attrs, BasicSchema) <- function(x, from = NULL, to = NULL) {
  result <- x@attrs
  if (!is.null(from)) {
    result <- Filter(function(a) a$dom == from, result)
  }
  if (!is.null(to)) {
    result <- Filter(function(a) a$codom == to, result)
  }
  result
}

#' @export
attrtypes <- S7::new_generic("attrtypes", "x")

S7::method(attrtypes, BasicSchema) <- function(x) {
  x@attrtypes
}

#' @export
types <- S7::new_generic("types", "x")

S7::method(types, BasicSchema) <- function(x) {
  c(x@obs, x@attrtypes)
}

#' @export
arrows <- S7::new_generic("arrows", "x")

S7::method(arrows, BasicSchema) <- function(x) {
  c(x@homs, x@attrs)
}

#' @export
dom <- S7::new_generic("dom", "x")

S7::method(dom, BasicSchema) <- function(x, f) {
  for (h in x@homs) if (h$name == f) return(h$dom)
  for (a in x@attrs) if (a$name == f) return(a$dom)
  cli::cli_abort("Arrow '{f}' not found in schema.")
}

#' @export
codom <- S7::new_generic("codom", "x")

S7::method(codom, BasicSchema) <- function(x, f) {
  for (h in x@homs) if (h$name == f) return(h$codom)
  for (a in x@attrs) if (a$name == f) return(a$codom)
  cli::cli_abort("Arrow '{f}' not found in schema.")
}

# Internal helpers
schema_is_hom <- function(schema, f) {
  any(vapply(schema@homs, function(h) h$name == f, logical(1)))
}

schema_is_attr <- function(schema, f) {
  any(vapply(schema@attrs, function(a) a$name == f, logical(1)))
}

schema_arrow_names <- function(schema) {
  c(
    vapply(schema@homs, function(h) h$name, character(1)),
    vapply(schema@attrs, function(a) a$name, character(1))
  )
}

# Print method
S7::method(format, BasicSchema) <- function(x, ...) {
  lines <- sprintf("BasicSchema with %d obs, %d homs, %d attrtypes, %d attrs",
                    length(x@obs), length(x@homs), length(x@attrtypes), length(x@attrs))
  obs_str <- paste(x@obs, collapse = ", ")
  lines <- c(lines, sprintf("  obs: %s", obs_str))
  if (length(x@homs) > 0) {
    hom_strs <- vapply(x@homs, function(h) sprintf("%s: %s → %s", h$name, h$dom, h$codom), character(1))
    lines <- c(lines, sprintf("  homs: %s", paste(hom_strs, collapse = ", ")))
  }
  if (length(x@attrtypes) > 0) {
    lines <- c(lines, sprintf("  attrtypes: %s", paste(x@attrtypes, collapse = ", ")))
  }
  if (length(x@attrs) > 0) {
    attr_strs <- vapply(x@attrs, function(a) sprintf("%s: %s → %s", a$name, a$dom, a$codom), character(1))
    lines <- c(lines, sprintf("  attrs: %s", paste(attr_strs, collapse = ", ")))
  }
  paste(lines, collapse = "\n")
}
