# Tables and equality -------------------------------------------------------

#' Convert ACSet object type to data.frame
#'
#' @param acs An ACSet.
#' @param ob Character: object type name.
#' @returns A data frame with part IDs and subpart columns.
#' @examples
#' sch <- BasicSchema(
#'   obs = c("V"),
#'   attrtypes = c("Name"),
#'   attrs = list(attr_spec("name", "V", "Name"))
#' )
#' g <- ACSet(sch)
#' add_parts(g, "V", 3, name = c("a", "b", "c"))
#' as_data_frame(g, "V")
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
#'
#' @param acs An ACSet.
#' @returns A named list of data frames, one per object type.
#' @export
tables <- function(acs) {
  result <- list()
  for (ob in objects(acs@schema)) {
    result[[ob]] <- as_data_frame(acs, ob)
  }
  result
}

#' Test structural equality of two ACSets
#'
#' @param x An ACSet.
#' @param y An ACSet.
#' @returns Logical: `TRUE` if the two ACSets are structurally equal.
#' @export
acset_equal <- function(x, y) {
  if (!identical(x@schema, y@schema)) return(FALSE)
  for (ob in objects(x@schema)) {
    if (nparts(x, ob) != nparts(y, ob)) return(FALSE)
  }
  for (nm in names(x@.data$subparts)) {
    xv <- x@.data$subparts[[nm]]$values
    yv <- y@.data$subparts[[nm]]$values
    if (length(xv) != length(yv)) return(FALSE)
    # Use element-wise comparison to handle integer/double differences
    if (!isTRUE(all(xv == yv, na.rm = FALSE))) {
      # Check NA positions match
      if (!identical(is.na(xv), is.na(yv))) return(FALSE)
      non_na <- !is.na(xv)
      if (!all(xv[non_na] == yv[non_na])) return(FALSE)
    }
  }
  TRUE
}
