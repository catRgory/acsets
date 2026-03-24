# Deletion operations -------------------------------------------------------

#' Remove a single part using pop-and-swap strategy
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
rem_part <- S7::new_generic("rem_part", "x")

S7::method(rem_part, ACSet) <- function(x, ob, part) {
  schema <- x@schema
  n <- nparts(x, ob)
  if (n == 0L || !has_part(x, ob, part)) {
    cli::cli_abort("Part {part} of '{ob}' does not exist.")
  }

  last <- n  # for IntParts, last part is always n

  # Clear incoming homs pointing to this part
  for (h in schema@homs) {
    if (h$codom == ob) {
      inc <- incident(x, part, h$name)
      if (length(inc) > 0L) {
        clear_subpart(x, inc, h$name)
      }
      # Repoint references from last → part
      if (last != part) {
        inc_last <- incident(x, last, h$name)
        if (length(inc_last) > 0L) {
          set_subpart(x, inc_last, h$name, rep(part, length(inc_last)))
        }
      }
    }
  }

  # Swap outgoing subparts from last to part position
  if (last != part) {
    for (h in schema@homs) {
      if (h$dom == ob) {
        col <- x@.data$subparts[[h$name]]
        val_last <- column_get(col, last)
        if (!is.na(val_last)) {
          column_set(col, part, val_last)
        } else {
          column_clear(col, part)
        }
      }
    }
    for (a in schema@attrs) {
      if (a$dom == ob) {
        col <- x@.data$subparts[[a$name]]
        val_last <- column_get(col, last)
        if (!is.na(val_last)) {
          column_set(col, part, val_last)
        } else {
          column_clear(col, part)
        }
      }
    }
  }

  # Clear the last slot and shrink
  for (h in schema@homs) {
    if (h$dom == ob) {
      col <- x@.data$subparts[[h$name]]
      column_clear(col, last)
      col$values <- col$values[-last]
      col$defined <- col$defined[-last]
    }
  }
  for (a in schema@attrs) {
    if (a$dom == ob) {
      col <- x@.data$subparts[[a$name]]
      column_clear(col, last)
      col$values <- col$values[-last]
      col$defined <- col$defined[-last]
    }
  }

  # Decrement part count
  x@.data$parts[[ob]]$n <- n - 1L
  invisible(x)
}

#' Remove multiple parts (must be processed from largest to smallest)
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
rem_parts <- S7::new_generic("rem_parts", "x")

S7::method(rem_parts, ACSet) <- function(x, ob, part_ids) {
  for (p in sort(part_ids, decreasing = TRUE)) {
    rem_part(x, ob, p)
  }
  invisible(x)
}

#' Remove a part and cascade to dependent parts
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
cascading_rem_part <- S7::new_generic("cascading_rem_part", "x")

S7::method(cascading_rem_part, ACSet) <- function(x, ob, part) {
  schema <- x@schema
  # Find and remove all parts in other objects that reference this part
  for (h in schema@homs) {
    if (h$codom == ob) {
      dependents <- incident(x, part, h$name)
      if (length(dependents) > 0L) {
        cascading_rem_parts(x, h$dom, dependents)
      }
    }
  }
  rem_part(x, ob, part)
  invisible(x)
}

#' Remove multiple parts with cascading
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
cascading_rem_parts <- S7::new_generic("cascading_rem_parts", "x")

S7::method(cascading_rem_parts, ACSet) <- function(x, ob, part_ids) {
  for (p in sort(part_ids, decreasing = TRUE)) {
    cascading_rem_part(x, ob, p)
  }
  invisible(x)
}

#' Garbage collection for BitSetParts (no-op for IntParts)
#'
#' @param x An ACSet.
#' @returns The ACSet, invisibly.
#' @param ... Arguments passed to methods.
#' @export
gc_acset <- S7::new_generic("gc_acset", "x")

S7::method(gc_acset, ACSet) <- function(x) {
  # Currently only IntParts is implemented, so this is a no-op.
  # BitSetParts gc would compact storage here.
  invisible(x)
}
