#' Update pin of forecast dataset on Connect
#' 
#' Pulls down the previous version of the pin, adds any new rows to the top, and
#' overwrites the pin. Pin is versioned, so previous versions can be inspected
#' on Posit Connect.
#'
#' @param fc_daily the wrangled forecast dataset target
#' @param name location of pin on board.  Default is the location published by
#'   Eric Scott under the name "fc_daily"
#'
pin_forecast <- function(fc_daily, name = "ericrscott/fc_daily") {
  board <- board_connect(auth = "envvar")
  #read pin
  old <- board |> pin_read(name)
  #add new forecast data
  fc_daily <- bind_rows(fc_daily, old) |> distinct()
  #update pin
  board |> pin_write(fc_daily, name)
}