# library(tidyverse)
# library(azmetr)
update_hourly <- function(db_hourly, ...) {
  hourly_prev <- open_dataset(db_hourly)
  
  #figure out where previous data left off
  last_date <- 
    hourly_prev |>
    pull(date_datetime, as_vector = TRUE) |>
    max()
  
  (round(last_date, units = "hours") + hours(1)) |> format("%H")
  #get data since last date in saved data
  start_date <- round(last_date, "hours") + hours(1)
  hourly_new <- az_hourly(start_date_time = format(start_date, "%Y-%m-%d %H"))
  
  # if API returns nothing
  if(nrow(hourly_new)==0) {
    
    return(invisible(db_hourly))
    
  } else {
    
    hourly <- 
      #arrow doesn't currently have bindings to bind_rows(), so need to collect() first.
      bind_rows(collect(hourly_prev), hourly_new) 
    
    #overwrite current year
    write_dataset(
      hourly,
      path = "data/hourly",
      format = "parquet",
      partitioning = "date_year"
    )
    return(invisible(db_hourly))
  }
}