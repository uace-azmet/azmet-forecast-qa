read_wrangle_hist <- function(hist_file) {
  read_csv(hist_file) |>
    # missing values in historic data coded as 999
    mutate(across(where(is.numeric), \(x) if_else(x == 999, NA_real_, x))) |> 
    filter(meta_station_id %in% azmetr::station_info$meta_station_id)
}