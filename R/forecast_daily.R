forecast_daily <- function(ts_daily, db_daily, var) {
  test_df <- 
    db_daily |> 
    arrow::open_dataset() |> 
    select(datetime, meta_station_id, {{var}}) |>
    #TODO: filter to use previous x days of data??
    collect() |>
    as_tsibble(key = meta_station_id, index = datetime) |> 
    tsibble::fill_gaps() |> 
    filter(datetime == max(datetime))
  
  fc <- forecast(ts_daily, newdata = test_df, h = 1)

  fc_tidy <- fc |>
    hilo(c(95, 99)) |>
    select(-{{var}})

  left_join(test_df, fc_tidy, by = c("datetime", "meta_station_id")) |>
    select(-.model) |>
    rename("fc_mean" = ".mean", "fc_95" = "95%", "fc_99" = "99%") |>
    mutate(lower_95 = fc_95$lower,
           upper_95 = fc_95$upper,
           lower_99 = fc_99$lower,
           upper_99 = fc_99$upper) |>
    select(-fc_95, -fc_99) |> 
    rename("obs" = {{var}}) |> 
    mutate(var = {{var}}, .before = obs) |> 
    as_tibble()
}