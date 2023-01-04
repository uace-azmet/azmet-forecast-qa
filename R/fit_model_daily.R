fit_ts_daily <- function(db_daily, var) {
  df <- db_daily |> 
    arrow::open_dataset() |> 
    select(datetime, meta_station_id, {{var}}) |> 
    #TODO: filter to use previous x days of data??
    collect() |>
    as_tsibble(key = meta_station_id, index = datetime) |> 
    tsibble::fill_gaps()
  
  train_df <- df |> 
    filter(datetime != max(datetime))
  
  test_df <- df |> 
    filter(datetime == max(datetime))
  
  # Adapted from https://robjhyndman.com/hyndsight/forecasting-weekly-data/
  #TODO there might be a better way to find the best value for K using optim()
  #TODO construct the formula for ARIMA better so the output shows the variable
  #name and the value of K instead of "i".  This is also necessary for getting
  #refit() to work because it reads that formula and parses it.
  best_aicc <- Inf
  bestfit <- list()
  for(i in 1:25) {
    cat("Trying K =", i, "\n")
    fit <-
      train_df |> 
      model(
        ARIMA( ~ pdq() + PDQ(0, 0, 0) + xreg(fourier(period = "1 year", K = i))),
      )
    
    # This is silly, but let's just optimize the mean AICc for all the sites. It
    # doesn't seem like the choice of K is very consequential, so this is
    # probably fine.  Otherwise, this would need to be applied to every site
    # separately.
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

# forecast_daily(db_daily, var = temp_air_meanC)
