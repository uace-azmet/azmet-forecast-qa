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
  
  #get data since last date in saved data
  daily_new <- az_daily(start_date = last_date + 1)
  
  # if API returns nothing
  if(nrow(daily_new)==0) {
    
    return(invisible(db_daily))
    
  } else {
  
    #arrow doesn't currently have bindings to bind_rows(), so need to collect()
    #first.  Only rows with years in common with the new data need to be
    #collect()ed and written out though.
    
    new_data_years <-
      daily_new |>
      pull(date_year) |>
      unique()
    
    daily <- 
      bind_rows(
        daily_prev |> 
          filter(date_year %in% new_data_years) |> collect(),
        daily_new
      ) 
  
  #overwrite current year
  write_dataset(
    daily,
    path = db_daily,
    format = "parquet",
    partitioning = "date_year"
  )
  return(invisible(db_daily))
  }
}
