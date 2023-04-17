#' Publish update daily dataset to Posit Connect
#' 
#' This pulls down a pinned dataset from viz.datascience.arizona.edu, queries
#' the AZMET API for only updated data, adds it to the data set and re-publishes
#' it.  This is faster than querying the AZMET API for all the data every day
#' and allows published shiny apps to use the daily data easily.
#'
#' @param name the name of the pin
#'
pin_daily <- function(name = "ericrscott/azmet_daily") {
  board <- board_connect(auth = "envvar")
  #read pin
  old <- board |> pin_read(name)
  #query API for only new data
  last_date <- max(old$datetime)
  new <- azmetr::az_daily(start_date = last_date + 1)
  update <- bind_rows(new, old) |> distinct()
  #update pin
  board |> pin_write(update, name)
}
