# library(arrow)
# library(lubridate)

#' Update daily data from API
#'
#' @param db_daily path to the parquet dataset partitioned by year
#' @param ... used only to add additional dependencies to trigger updates with
#'   `targets`
#'
#' @return invisibly returns the `db_daily` path 
update_daily <- function(db_daily, ...) {
  daily_prev <- open_dataset(db_daily)
  
  #figure out where previous data left off
  last_date <- 
    daily_prev |>
    pull(datetime, as_vector = TRUE) |>
    max()
  
  #read in the current year only because that's how it's partitioned and only
  #the most recent year of data will need to get overwritten.
  daily_current_year <- 
    daily_prev |> 
    filter(date_year == year(last_date)) |>
    collect()
  
  #get data since last date in saved data
  daily_new <- az_daily(start_date = last_date + 1)
  
  if(is.na(daily_new)) {
    
    return(invisible(db_daily))
    
  } else {
    
  daily <- 
    bind_rows(daily_current_year, daily_new) 
  
  #overwrite current year
  write_daily(daily, path = db_daily)
  return(invisible(db_daily))
  }
}
