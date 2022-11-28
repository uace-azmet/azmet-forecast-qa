# library(lubridate)
# library(arrow)
init_hourly <- function(init_datetime) {
  
  init_datetime <- ymd_h(init_datetime)
  format(init_datetime, "%Y-%m-%d %H")
  hourly <-
    azmetr::az_hourly(
      start_date_time = format(init_datetime, "%Y-%m-%d %H"),
      end_date_time = format(init_datetime + days(1), "%Y-%m-%d %H")
    )
  write_dataset(
    hourly,
    path = "data/hourly",
    format = "parquet",
    partitioning = "date_year"
  )
  invisible("data/hourly")
}

