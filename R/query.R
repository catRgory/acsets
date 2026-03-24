# Query DSL ----------------------------------------------------------------
# SQL-like query interface for ACSets: From() |> Where() |> Select()

#' @export
From <- function(acs, ob) {
  ids <- parts(acs, ob)
  structure(list(
    acs = acs,
    ob = ob,
    ids = ids
  ), class = "acset_query")
}

#' @export
Where <- function(query, f, op, value) {
  stopifnot(inherits(query, "acset_query"))
  vals <- subpart(query$acs, query$ids, f)
  mask <- op(vals, value)
  mask[is.na(mask)] <- FALSE
  query$ids <- query$ids[mask]
  query
}

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
