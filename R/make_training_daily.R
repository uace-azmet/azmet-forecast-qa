#' Make once yearly training data
#'
#' I think this will make a target that only invalidates once a year, but still
#' depends on db_daily existing.
#'
#' @param db_daily path to parquet file store
#'
#' @return arrow_dplyr_query
make_training_daily <- function(db_daily) {
  df <- 
    db_daily |>
    arrow::open_dataset() 
  cutoff <- 
    lubridate::floor_date(lubridate::today(), unit = "year")
  df|> 
    dplyr::filter(datetime < cutoff)
}


