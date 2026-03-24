# Query DSL ----------------------------------------------------------------
# SQL-like query interface for ACSets: From() |> Where() |> Select()

#' Start a query on an ACSet object type
#'
#' @param acs An ACSet.
#' @param ob Character: object type to query.
#' @returns An `acset_query` object for piping to [Where()] and [Select()].
#' @examples
#' sch <- BasicSchema(
#'   obs = c("V"),
#'   attrtypes = c("Name", "Age"),
#'   attrs = list(attr_spec("name", "V", "Name"),
#'                attr_spec("age", "V", "Age"))
#' )
#' g <- ACSet(sch)
#' add_parts(g, "V", 3, name = c("Alice", "Bob", "Carol"),
#'           age = c(30, 25, 35))
#' # Query pipeline: find vertices with age > 28
#' result <- From(g, "V") |> Where("age", `>`, 28) |> Select("name", "age")
#' result
#' @export
From <- function(acs, ob) {
  ids <- parts(acs, ob)
  structure(list(
    acs = acs,
    ob = ob,
    ids = ids
  ), class = "acset_query")
}

#' Filter query results by a subpart value
#'
#' @param query An `acset_query` object from [From()].
#' @param f Character: morphism or attribute name.
#' @param op A comparison function (e.g. `==`, `<`).
#' @param value The value to compare against.
#' @returns The filtered `acset_query` object.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("V"),
#'   attrtypes = c("Name"),
#'   attrs = list(attr_spec("name", "V", "Name"))
#' )
#' g <- ACSet(sch)
#' add_parts(g, "V", 3, name = c("Alice", "Bob", "Carol"))
#' From(g, "V") |> Where("name", `==`, "Bob") |> Select("name")
#' @export
Where <- function(query, f, op, value) {
  stopifnot(inherits(query, "acset_query"))
  vals <- subpart(query$acs, query$ids, f)
  mask <- op(vals, value)
  mask[is.na(mask)] <- FALSE
  query$ids <- query$ids[mask]
  query
}

#' Select columns from a query and return a data frame
#'
#' @param query An `acset_query` object from [From()] or [Where()].
#' @param ... Character names of subparts to include as columns.
#' @returns A data frame with the selected columns.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("V"),
#'   attrtypes = c("Name"),
#'   attrs = list(attr_spec("name", "V", "Name"))
#' )
#' g <- ACSet(sch)
#' add_parts(g, "V", 3, name = c("Alice", "Bob", "Carol"))
#' From(g, "V") |> Select("name")
#' @export
Select <- function(query, ...) {
  stopifnot(inherits(query, "acset_query"))
  fields <- c(...)
  if (length(fields) == 0L) return(data.frame(id = query$ids))
  result <- data.frame(id = query$ids)
  for (f in fields) {
    result[[f]] <- subpart(query$acs, query$ids, f)
  }
  result
}
