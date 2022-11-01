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
    )) |> 
    #make station names consistent
    mutate(meta_station_name = case_when(
      meta_station_id == "az12" ~ "Phoenix Greenway",
      meta_station_id == "az14" ~ "Yuma N.Gila",
      meta_station_id == "az15" ~ "Phoenix Encanto",
      meta_station_id == "az28" ~ "Mohave-2",
      TRUE ~ meta_station_name
    )) |> 
    filter(meta_station_id != "az99") #remove test station
  
  # convert to tsibble
  build_tsibble(
    daily,
    key = c(meta_station_id, meta_station_name),
    index = datetime,
    # interval = new_interval(year = 1) #TODO figure out how to get this right
  ) |> 
    #make gaps explicit
    fill_gaps(.full = TRUE)
  
}