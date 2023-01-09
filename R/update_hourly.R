#' Update hourly data from API
#'
#' @param db_hourly path to hourly data store ("data/hourly")
#' @param db_hourly_init used only to add additional dependencies to trigger updates with
#'   `targets`
#'
#' @return invisibly returns the `db_hourly` path 
#' 
update_hourly <- function(db_hourly, db_hourly_init) {
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
    
    #arrow doesn't currently have bindings to bind_rows(), so need to collect()
    #first.  Only rows with years in common with the new data need to be
    #collect()ed and written out though.
    new_data_years <-
      hourly_new |>
      pull(date_year) |>
      unique()
    
    hourly <- 
      bind_rows(
        hourly_prev |> 
          filter(date_year %in% new_data_years) |> collect(),
        hourly_new
      ) 

    #overwrite current year
    write_dataset(
      hourly,
      path = db_hourly,
      format = "parquet",
      partitioning = "date_year"
    )
    return(invisible(db_hourly))
  }
}