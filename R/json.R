# JSON serialization --------------------------------------------------------
# Compatible with py-acsets, ts-acsets, acsets4j format.

#' Generate JSON-compatible list from an ACSet
#'
#' @param x An ACSet.
#' @returns A nested list suitable for JSON serialization.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("E", "V"),
#'   homs = list(hom("src", "E", "V"), hom("tgt", "E", "V")),
#'   attrtypes = c("Name"),
#'   attrs = list(attr_spec("name", "V", "Name"))
#' )
#' Graph <- acset_type(sch)
#' g <- Graph(V = 2, E = 1, src = 1L, tgt = 2L, name = c("a", "b"))
#' json_list <- generate_json_acset(g)
#' str(json_list)
#' # Round-trip via JSON
#' g2 <- parse_json_acset(Graph, json_list)
#' acset_equal(g, g2)
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
#'
#' @param constructor An acset_constructor from [acset_type()].
#' @param input A nested list (typically from JSON) representing ACSet data.
#' @returns An ACSet instance.
#' @examples
#' sch <- BasicSchema(obs = c("V"), attrtypes = c("Name"),
#'                    attrs = list(attr_spec("name", "V", "Name")))
#' Verts <- acset_type(sch)
#' input <- list(V = list(list(`_id` = 1L, name = "a"),
#'                        list(`_id` = 2L, name = "b")))
#' g <- parse_json_acset(Verts, input)
#' nparts(g, "V")
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
#'
#' @param x An ACSet.
#' @param path File path to write to.
#' @returns The file path, invisibly.
#' @examples
#' sch <- BasicSchema(obs = c("V"), attrtypes = c("Name"),
#'                    attrs = list(attr_spec("name", "V", "Name")))
#' Verts <- acset_type(sch)
#' g <- Verts(V = 2, name = c("a", "b"))
#' tmp <- tempfile(fileext = ".json")
#' write_json_acset(g, tmp)
#' g2 <- read_json_acset(Verts, tmp)
#' acset_equal(g, g2)
#' unlink(tmp)
#' @export
write_json_acset <- function(x, path) {
  json_data <- generate_json_acset(x)
  jsonlite::write_json(json_data, path, auto_unbox = TRUE, pretty = TRUE)
  invisible(path)
}

#' Read an ACSet from JSON file
#'
#' @param constructor An acset_constructor from [acset_type()].
#' @param path File path to read from.
#' @returns An ACSet instance.
#' @export
read_json_acset <- function(constructor, path) {
  input <- jsonlite::read_json(path)
  parse_json_acset(constructor, input)
}

# Schema serialization
#' Generate a JSON-compatible list from a schema
#'
#' @param schema A BasicSchema.
#' @returns A list suitable for JSON serialization.
#' @export
generate_json_schema <- function(schema) {
  list(
    obs = as.list(schema@obs),
    homs = lapply(schema@homs, function(h) list(name = h$name, dom = h$dom, codom = h$codom)),
    attrtypes = as.list(schema@attrtypes),
    attrs = lapply(schema@attrs, function(a) list(name = a$name, dom = a$dom, codom = a$codom))
  )
}

#' Parse a JSON-compatible list into a BasicSchema
#'
#' @param input A list (typically from JSON) representing a schema.
#' @returns A BasicSchema object.
#' @export
parse_json_schema <- function(input) {
  BasicSchema(
    obs = vapply(input$obs, identity, character(1)),
    homs = lapply(input$homs, function(h) list(name = h$name, dom = h$dom, codom = h$codom)),
    attrtypes = vapply(input$attrtypes, identity, character(1)),
    attrs = lapply(input$attrs, function(a) list(name = a$name, dom = a$dom, codom = a$codom))
  )
}
