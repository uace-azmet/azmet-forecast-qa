#TODO: could be combined with forecast_daily() to simplify.  Doing it separate is useful for model diagnostics though.
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
  
  #TODO: get this to work with either a string for var or tidyeval.
  # maybe as.formula() ??
  ts <- train_df |> 
    model(SNAIVE( ~ lag(365)))
  ts
  
  # fc <- forecast(ts, newdata = test_df, h = 1)
  #
  # fc_tidy <- fc |> 
  #   hilo(c(95, 99)) |>
  #   select(-{{var}})
  # 
  # left_join(test_df, fc_tidy, by = c("datetime", "meta_station_id")) |> 
  #   select(-.model) |>
  #   rename("fc_mean" = ".mean", "fc_95" = "95%", "fc_99" = "99%") |> 
  #   mutate(lower_95 = fc_95$lower,
  #          upper_95 = fc_95$upper,
  #          lower_99 = fc_99$lower,
  #          upper_99 = fc_99$upper) |> 
  #   select(-fc_95, -fc_99)
}

# forecast_daily(db_daily, var = temp_air_meanC)
