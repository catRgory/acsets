# Tables and equality -------------------------------------------------------

#' Convert ACSet object type to data.frame
#' @export
as_data_frame <- function(acs, ob) {
  n <- nparts(acs, ob)
  if (n == 0L) {
    # Empty data frame with correct columns
    cols <- list(id = integer(0))
    for (h in homs(acs@schema, from = ob)) cols[[h$name]] <- integer(0)
    for (a in attrs(acs@schema, from = ob)) cols[[a$name]] <- character(0)
    return(as.data.frame(cols))
  }
  ids <- parts(acs, ob)
  cols <- list(id = ids)
  for (h in homs(acs@schema, from = ob)) {
    cols[[h$name]] <- subpart(acs, ids, h$name)
  }
  for (a in attrs(acs@schema, from = ob)) {
    cols[[a$name]] <- subpart(acs, ids, a$name)
  }
  as.data.frame(cols)
}

#' Get all tables from an ACSet
#' @export
tables <- function(acs) {
  result <- list()
  for (ob in objects(acs@schema)) {
    result[[ob]] <- as_data_frame(acs, ob)
  }
  result
}

#' Test structural equality of two ACSets
#' @export
acset_equal <- function(x, y) {
  if (!identical(x@schema, y@schema)) return(FALSE)
  for (ob in objects(x@schema)) {
    if (nparts(x, ob) != nparts(y, ob)) return(FALSE)
  }
  for (nm in names(x@.data$subparts)) {
    xv <- x@.data$subparts[[nm]]$values
    yv <- y@.data$subparts[[nm]]$values
    if (!identical(xv, yv)) return(FALSE)
  }
  TRUE
}
