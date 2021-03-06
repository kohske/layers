#' Render a grid grob from a geom and a dataset.
#' 
#' This is the key method to implement when creating a new geom.  Given a
#' geom and its paramters, and a dataset, it renders the data to produce a
#' grid grob. The data supplied to this function has already been scaled,
#' so all values are interpretable by grid, but it has not been fleshed
#' out with geom defaults and aesthetics parameters - use 
#' \code{\link{calc_aesthetics}} to do so.
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

#' Process data for the geom.
#'
#' This method is run just prior to creating the grob, and is used to get the
#' data into a format which requires minimal processing to be supplied to a
#' geom. This is separated out into a separate method because a number of 
#' grobs process data in a slightly different way but otherwise inherit all
#' other behaviours, and to make testing easier.
#' 
#' The default behaviour uses \code{\link{calc_aesthetics}} to update the
#' data with the aesthetic parameters and defaults stored in the geom.
#' 
#' @export
#' @S3method geom_data default
#' @return a list, suitable for operation with \code{\link{geom_data}}
geom_data <- function(geom, data) UseMethod("geom_data")
geom_data.default <- function(geom, data) {
  calc_aesthetics(geom, data)  
}


#' @export
#' @S3method geom_visualise default
geom_visualise <- function(geom, data) UseMethod("geom_visualise")
geom_visualise.default <- function(geom, data = list()) {
  geom_grob(geom, data, default.units = "npc")
}

geom_name <- function(geom) {
  str_c("geom_", class(geom)[1])
}

#' Convenience method for plotting geoms.
#' 
#' @export
geom_plot <- function(geom, data = list(), munch = FALSE) {
  data <- add_group(data)
  data <- geom_data(geom, data)
  if (munch) {
    munched <- geom_munch(geom, data)
    geom <- munched$geom
    data <- munched$data
  }
  grob <- geom_draw(geom, data)

  grid.newpage()
  pushViewport(dataViewport(c(data$x, data$xmin, data$xmax), 
    c(data$y, data$ymin, data$ymax)))
  grid.draw(grob)
  
  invisible(grob)
}

geom_draw <- function(geom, data) {
  name_grob(geom_grob(geom, data), geom_name(geom))
}
name_grob <- function(grob, name) {
  grob$name <- grobName(grob, name)
  grob
}

#' Deparse a geom into the call that created it.
#' Useful for serialising ggplot2 objects back into R code.
geom_deparse <- function(geom) {
  values <- unlist(lapply(geom, deparse, control = NULL))
  args <- str_c(names(geom), " = ", values, collapse = ", ")
  
  str_c(geom_name(geom), "(", args, ")")
}

geom_visualise <- function(geom, data = list()) {
  data <- modifyList(aes_icon(geom), data)
  geom_plot(geom, as.data.frame(data, stringsAsFactors = FALSE))
}


geom_from_call <- function(name, arguments = NULL) {
  if (is.null(arguments)) {
    parent <- sys.frame(-1)
    arguments <- as.list(parent)
  }
  
  geom <- structure(arguments, class = c(name, "geom"))
  check_aesthetic_params(geom, geom$aesthetics)
  geom
}

print.geom <- function(x, ...) {
  cat(geom_deparse(x), "\n")
}

