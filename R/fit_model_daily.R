#' Fit timeseries models to daily data
#' 
#' Fits a non-seasonal ARIMA model with a fourier term to capture seasonality. 
#' 
#' @note This can't be run on parallel workers because `db_daily` hasn't been
#'   `collect()`ed yet and is just a pointer to files rather than an actual data
#'   frame.
#'
#' @param db_daily the db_daily target which is a filtered (but not `collect()`ed) arrow dataset
#' @param var unquoted name of weather variable column
#'
#' @return a model object
fit_model_daily <- function(training_daily, var) {
  df <- 
    training_daily |> 
    select(datetime, meta_station_id, all_of({{var}})) |> 
    as_tsibble(key = meta_station_id, index = datetime) |> 
    tsibble::fill_gaps()
  
  train_df <- df |> 
    filter(datetime != max(datetime))
  
  test_df <- df |> 
    filter(datetime == max(datetime))
  
  # Adapted from https://robjhyndman.com/hyndsight/forecasting-weekly-data/
  #TODO there might be a better way to find the best value for K, or maybe it's
  #safer to just set it sufficiently high since it is the "maximum order of the
  #fourier terms"
  
  best_aicc <- Inf
  bestfit <- list()
  for(i in 1:25) {
    cat("Trying K =", i, "\n")
    # i = 1 #Debug
    
    # Construct the formula for ARIMA() as a call so the output shows the actual
    # variable name and value for K (not just K = i).  This looks nicer in the
    # output, suppresses some warnings from fable, and is necessary for refit() to
    # work correctly since it parses the formula.
    arima_call <- 
      call(
        "ARIMA",
        str2lang(glue::glue("{var} ~ pdq() + PDQ(0,0,0) + xreg(fourier(period = '1 year', K = {i}))"))
      )
    fit <-
      train_df |> 
      model(
        eval(arima_call), #evaluate the constructed call
      )
    
    # This is silly, but let's just optimize the mean AICc across all the sites.
    # It doesn't seem like the choice of K is very consequential, so this is
    # probably fine.  Otherwise, this would need to be applied to every site
    # separately and each site would likely have different values for K.
    
    fit_aicc <- glance(fit)$AICc |> mean()
    if(fit_aicc < best_aicc) {
      bestfit <- fit
      best_aicc <- fit_aicc
    } else {
      break
    }
  }
  bestfit
}

# fit_model_daily(db_daily, var = temp_air_meanC)
