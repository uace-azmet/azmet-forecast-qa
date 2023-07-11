#' Create a 1 day forecast from timeseries models
#' 
#' Uses time
#'
#' @param model one branch of the `models_daily` target
#' @param daily the `daily` target
#' @param var character; one variable name in `db_daily`
#'
#' @return a tibble
forecast_daily <- function(model, daily, var) {
  #wrangle data
  df <- 
   daily |>
    #remove stations that don't have any data
    # filter(if_all(matches(var), ~!is.na(.))) |> 
    as_tsibble(key = meta_station_id, index = datetime) |> 
    tsibble::fill_gaps()
  
  #data to re-fit (not re-estimate) model:
  refit_df <-
    df |>
    filter(datetime < max(datetime))
  
  #data to forecast:
  fc_df <- 
    df |>
    filter(datetime == max(datetime)) |> 
    #remove stations that don't have any data
    filter(if_all(matches(var), ~!is.na(.)))
    
  #refit model
  mod_refit <- fabletools::refit(model, new_data = refit_df)
  
  #create forecast
  fc <- fabletools::forecast(mod_refit, newdata = fc_df, h = 1)
  
  #tidy forecast
  fc_tidy <- fc |>
    hilo(c(95, 99)) |>
    select(-matches(var)) |> #remove column with distribution (named after the variable)
    select(-.model) |> 
    rename("fc_mean" = ".mean", "fc_95" = "95%", "fc_99" = "99%") |> 
    mutate(lower_95 = fc_95$lower,
           upper_95 = fc_95$upper,
           lower_99 = fc_99$lower,
           upper_99 = fc_99$upper) |>
    select(-fc_95, -fc_99)
  
  fc_df |> 
    select(datetime, meta_station_id, meta_station_name, all_of(var)) |> 
    left_join(fc_tidy, by = c("datetime", "meta_station_id")) |>
    rename("obs" = matches(var)) |> 
    mutate(varname = var, .before = obs) |> 
    as_tibble()
}