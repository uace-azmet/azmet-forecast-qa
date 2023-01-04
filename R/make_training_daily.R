#' Make once yearly training data
#'
#' I think this will make a target that only invalidates downstream targets once
#' a year, but still depends on db_daily existing.
#'
#' @param db_daily path to parquet file store
#'
#' @return a tibble
make_training_daily <- function(db_daily, forecast_qa_vars) {
  df <- 
    db_daily |>
    arrow::open_dataset() 
  cutoff <- 
    lubridate::floor_date(lubridate::today(), unit = "year")
  df|> 
    dplyr::filter(datetime < cutoff) |> 
    dplyr::select(datetime, meta_station_id, all_of({{forecast_qa_vars}})) |> 
    dplyr::collect()
    
}


