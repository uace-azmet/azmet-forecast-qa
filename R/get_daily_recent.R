get_daily_recent <- function(daily_hist) {
  daily_recent <- 
    az_daily(start_date = max(daily_hist$datetime) + 1,
             end_date = "2022-10-20")
  daily_recent
}