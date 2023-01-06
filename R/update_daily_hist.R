#' Add API data to historical data and create a data store
#' 
#' Binds historical data (2003-01-01 through 2020-12-31) to more recent data
#' (through 2022-10-31) retrieved from the AZMet API.  Does some data cleaning
#' to match the historical data to the API data, then writes data out as a
#' partitioned parquet data store.
#'
#' @param daily_hist the historical dataset tibble
#'
#' @return invisibly, the path "data/daily"
update_daily_hist <- function(legacy_daily) {
  daily_recent <- 
    az_daily(start_date = max(legacy_daily$datetime) + 1,
             end_date = "2022-10-31")
  daily <- bind_rows(legacy_daily, daily_recent)
  daily <- daily |> 
    #remove duplicates
    filter(!are_duplicated(
      daily,
      key = c(meta_station_id, meta_station_name),
      index = datetime
    )) |> 
    #make station names consistent with API data
    mutate(meta_station_name = case_when(
      meta_station_id == "az12" ~ "Phoenix Greenway",
      meta_station_id == "az14" ~ "Yuma N.Gila",
      meta_station_id == "az15" ~ "Phoenix Encanto",
      meta_station_id == "az28" ~ "Mohave-2",
      TRUE ~ meta_station_name
    )) |> 
    filter(meta_station_id != "az99") #remove test station
  write_dataset(
    daily,
    path = "data/daily",
    format = "parquet",
    partitioning = "date_year"
  )
  daily
}