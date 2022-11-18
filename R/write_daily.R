# library(arrow)
# library(targets)
# tar_load(daily)

#' Write daily data to parquet files
#' 
#' A simple wrapper to `arrow::write_dataset()` to set some defaults.  Writes to
#' parquet files partitioned by year so that there is a separate file for each
#' year of data stored in `path`.  This makes it easier to update the data by
#' only overwriting the most recent year when new data is added on from the API.
#'
#' @param daily a tibble
#' @param path the path to write the parquet files
#'
#' @return invisibly returns the write path
write_daily <- function(daily, path = "./data/daily/") {
  write_dataset(
    daily,
    path = path,
    format = "parquet",
    partitioning = "date_year"
  )
  invisible(file.path(path))
}

