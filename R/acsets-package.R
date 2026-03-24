#' @import S7
#' @keywords internal
#' @aliases acsets-package
"_PACKAGE"

.onLoad <- function(libname, pkgname) {
  S7::methods_register()
}
