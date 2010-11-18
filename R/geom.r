#' Render a grid grob from a geom and a dataset.
#' 
#' @return a grob
geom_grob <- function(geom, data, ...) UseMethod("geom_grob")

#' Prepare the data for munching (if needed).
#'
#' This function will only be run if the coordinate system is non-linear, and
#' requires "munching" (breaking the data into small enough pieces that they
#' will still be linear after transformation).
#'
#' This usually requires reparameterising the geom to by something that can
#' be drawn by \code{\link{geom_path}} or \code{\link{geom_polygon}}, and so
#' the function should return both the data and the new geom to be used to
#' draw the data. 
#' 
#' The default method leaves the data and geom unchanged.
#'
#' @return list containing updated data and geom that should be used to draw
#'   the data
#' @export
#' @S3method geom_premunch default
geom_munch <- function(geom, data) UseMethod("geom_munch")
geom_munch.default <- function(geom, data) list(geom = geom, data = data)

#' Reparameterise the data.
#'
#' Converts widths and heights to x and y coordinates.  This is used to 
#' ensure that all geoms, regardless of how they are specified, are converted
#' to a common coordinate system that uses x, xmin, xmax, y, ymin and ymax.
#'
#' @return a data frame
geom_reparam <- function(geom, data) UseMethod("geom_reparam")
geom_reparam.default <- function(geom, data) data

#' Default related stat and adjust.
#'
#' The defaults are the identity functions which leave the data unchanged.
#' 
#' @aliases geom_stat geom_adjust
#' @export geom_stat geom_adjust
#' @usage geom_stat(geom, ...)
#' @usage geom_adjust(geom, ...)
#' @param ... Other arguments passed on to the object creation function.  
#'   These are used when initialised a geom from a name and list of 
#'   parameters, which may belong to the stat or the position adjustment.
geom_stat <- function(geom, ...) UseMethod("geom_stat")
geom_adjust <- function(geom, ...) UseMethod("geom_adjust")

geom_stat.default <- function(geom, ...) stat_identity()
geom_adjust.default <- function(geom, ...) adjust_identity()

geom_visualize <- function(geom, data) UseMethod("geom_visualise")
geom_visualize.default <- function(geom, data = list()) {
  geom_grob(geom, data, default.units = "npc")
}

geom_draw <- function(geom, data) {
  name <- paste(class(geom), collapse = "-")
  ggname(name, geom_grob(geom, data))
}

#' Deparse a geom into the call that created it.
#' Useful for serialising ggplot2 objects back into R code.
geom_deparse <- function(geom) {
  args <- str_c(names(geom), " = ", lapply(geom, deparse), collapse = ", ")
  str_c(geom_name(geom), "(", args, ")")
}

geom_from_call <- function(name, call = NULL) {
  if (is.null(call)) {
    call <- match.call(sys.call(sys.parent(2), expand.dots = FALSE))
  }
  
  call["..."] <- NULL
  call[[1L]] <- as.name("list")
  
  geom <- structure(eval(call), class = name)
  check_set_aesthetics(geom)
  geom
}

geom_from_layer <- function(name, call = NULL) {
  if (is.null(call)) {
    call <- match.call(sys.call(sys.parent(2), expand.dots = FALSE))
  }
  
  aes <- call$`...`[aes_all(structure(class = name))]
    
  call$`...` <- NULL
  call$aesthetics <- do.call("call", list(as.name(list), aes))
  
  geom_from_call(name, call)
}

geom_name <- function(geom) {
  str_c("geom_", class(geom)[1])
}