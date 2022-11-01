forecast_sol_rad <- function(ts_sol_rad, daily_test) {
  forecast(ts_sol_rad, newdata = daily_test |> select(sol_rad_total))
}