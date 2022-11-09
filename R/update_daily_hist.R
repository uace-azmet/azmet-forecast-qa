# adds data starting with last date of historic through october 2022
update_daily_hist <- function(daily_hist) {
  daily_recent <- 
    az_daily(start_date = max(daily_hist$datetime) + 1,
             end_date = "2022-10-31")
  bind_rows(daily_hist, daily_recent)
}