update_daily <- function(daily_hist, daily_recent) {
  daily_prev <- bind_rows(daily_hist, daily_recent)
  daily_new <- az_daily(start_date = max(daily_prev$datetime) + 1)
  
  daily <- 
    bind_rows(daily_prev, daily_new) 
  
  daily <- daily |> 
    #remove duplicates
    filter(!are_duplicated(
      daily,
      key = c(meta_station_id, meta_station_name),
      index = datetime
    )) 
  
  # convert to tsibble
  as_tsibble(daily, key = c(meta_station_id, meta_station_name), index = datetime) |> 
    #make gaps explicit
    fill_gaps(.full = TRUE)
  
}