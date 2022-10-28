#' Fit timeseries model to sol_rad_total
#' 
#' Currently uses a seasonal naive model.  Not the best probably.
#' 
#' @param daily_train weather data except current day
#'
#' @return a mable
fit_ts_sol_rad <- function(daily_train) {
  daily_train |> 
    select(sol_rad_total) |> 
    model(SNAIVE(sol_rad_total ~ lag(365)))
}