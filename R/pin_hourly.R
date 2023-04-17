#' Publish update hourly dataset to Posit Connect
#' 
#' This pulls down a pinned dataset from viz.datascience.arizona.edu, queries
#' the AZMET API for only updated data, adds it to the data set and re-publishes
#' it.  This is faster than querying the AZMET API for all the data every day
#' and allows published shiny apps to use the hourly data easily.
#'
#' @param name the name of the pin
#'
pin_hourly <- function(name = "ericrscott/azmet_hourly") {
  board <- board_connect(auth = "envvar")
  #read pin
  old <- board |> pin_read(name)
  #query API for only new data
  last_date <- max(old$date_datetime)
  new <- azmetr::az_hourly(start_date_time = last_date)
  update <- bind_rows(new, old) |> distinct()
  #update pin
  board |> pin_write(update, name)
}
