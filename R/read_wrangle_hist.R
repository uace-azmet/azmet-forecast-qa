#' Read and wrangle historical AZmet data
#' 
#' Historical data (currently only daily) is scraped by the script in
#' wrangling/scrape_historic.R and saved as data/daily_hist.csv.  This function
#' reads that csv in and does some data wrangling to help in join up with the
#' modern data.  The historical data starts in 2003 since it appears there were
#' some changes to how the data was stored in that year.
#' 
#' @param hist_file the path to daily_hist.csv (or a target that holds that path)
#'
#' @return a tibble
read_wrangle_hist <- function(hist_file) {
  read_csv(hist_file) |>
    # missing values in historic data coded as 999
    mutate(across(where(is.numeric), \(x) if_else(x == 999, NA_real_, x))) |> 
    filter(meta_station_id %in% azmetr::station_info$meta_station_id)
}