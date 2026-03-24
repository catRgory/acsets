# JSON serialization --------------------------------------------------------
# Compatible with py-acsets, ts-acsets, acsets4j format.

#' Generate JSON-compatible list from an ACSet
#' @export
generate_json_acset <- function(x) {
  schema <- x@schema
  result <- list()

  for (ob in schema@obs) {
    n <- nparts(x, ob)
    if (n == 0L) {
      result[[ob]] <- list()
      next
    }
    ids <- parts(x, ob)
    rows <- vector("list", n)
    for (i in seq_along(ids)) {
      row <- list(`_id` = ids[i])
      for (h in homs(schema, from = ob)) {
        val <- column_get(x@.data$subparts[[h$name]], ids[i])
        row[[h$name]] <- if (is.na(val)) NULL else val
      }
      for (a in attrs(schema, from = ob)) {
        val <- column_get(x@.data$subparts[[a$name]], ids[i])
        row[[a$name]] <- if (is.na(val)) NULL else val
      }
      rows[[i]] <- row
    }
    result[[ob]] <- rows
  }
  result
}

#' Parse a JSON-compatible list into an ACSet
#' @export
parse_json_acset <- function(constructor, input) {
  if (inherits(constructor, "acset_constructor")) {
    schema <- attr(constructor, "schema")
    index <- attr(constructor, "index")
    acs <- ACSet(schema, index = index)
  } else {
    cli::cli_abort("constructor must be an acset_constructor")
  }

  # First pass: add parts
  parts_map <- list()
  for (ob in schema@obs) {
    rows <- input[[ob]]
    if (is.null(rows) || length(rows) == 0L) {
      parts_map[[ob]] <- integer(0)
      next
    }
    n <- length(rows)
    new_ids <- add_parts(acs, ob, n)
    # Map original _id to new sequential IDs
    orig_ids <- vapply(rows, function(r) r[["_id"]], integer(1))
    id_map <- new_ids
    names(id_map) <- as.character(orig_ids)
    parts_map[[ob]] <- id_map
  }

  # Second pass: set subpart values
  for (ob in schema@obs) {
    rows <- input[[ob]]
    if (is.null(rows) || length(rows) == 0L) next
    for (i in seq_along(rows)) {
      row <- rows[[i]]
      for (h in homs(schema, from = ob)) {
        val <- row[[h$name]]
        if (!is.null(val)) {
          # Remap foreign key through parts_map
          mapped_val <- parts_map[[h$codom]][[as.character(val)]]
          if (!is.null(mapped_val)) {
            set_subpart(acs, i, h$name, as.integer(mapped_val))
          }
        }
      }
      for (a in attrs(schema, from = ob)) {
        val <- row[[a$name]]
        if (!is.null(val)) {
          set_subpart(acs, i, a$name, val)
        }
      }
    }
  }
  acs
}

#' Write an ACSet to JSON file
#' @export
write_json_acset <- function(x, path) {
  json_data <- generate_json_acset(x)
  jsonlite::write_json(json_data, path, auto_unbox = TRUE, pretty = TRUE)
  invisible(path)
}

#' Read an ACSet from JSON file
#' @export
read_json_acset <- function(constructor, path) {
  input <- jsonlite::read_json(path)
  parse_json_acset(constructor, input)
}

# Schema serialization
#' @keywords internal
generate_json_schema <- function(schema) {
  list(
    obs = as.list(schema@obs),
    homs = lapply(schema@homs, function(h) list(name = h$name, dom = h$dom, codom = h$codom)),
    attrtypes = as.list(schema@attrtypes),
    attrs = lapply(schema@attrs, function(a) list(name = a$name, dom = a$dom, codom = a$codom))
  )
}

#' @keywords internal
parse_json_schema <- function(input) {
  BasicSchema(
    obs = vapply(input$obs, identity, character(1)),
    homs = lapply(input$homs, function(h) list(name = h$name, dom = h$dom, codom = h$codom)),
    attrtypes = vapply(input$attrtypes, identity, character(1)),
    attrs = lapply(input$attrs, function(a) list(name = a$name, dom = a$dom, codom = a$codom))
  )
}
