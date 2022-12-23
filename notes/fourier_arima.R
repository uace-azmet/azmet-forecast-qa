library(targets)
library(fable)
library(tidyverse)
library(arrow)
library(tsibble)
# library(forecast)
tar_load(db_daily)


df <- 
  db_daily |> 
  arrow::open_dataset() |> 
  select(datetime, meta_station_id, wind_spd_mean_mps) |> 
  #TODO: filter to use previous x days of data??
  collect() |>
  as_tsibble(key = meta_station_id, index = datetime) |> 
  tsibble::fill_gaps()

train_df <- df |> 
  filter(meta_station_id %in% c("az01", "az02", "az04")) |>
  filter(datetime < lubridate::ymd("2020-01-01"))

test_df <- df |> 
  filter(meta_station_id %in% c("az01", "az02", "az04")) |>
  filter(datetime >= lubridate::ymd("2020-01-01"))


# Implement in fable?
# TODO: there's a better way to optimize K with optim() I'm sure.
library(fable)
best_aicc <- Inf
bestfit <- list()
for(i in 1:25) {
  cat("Trying K =", i, "\n")
  fit <-
    train_df |> 
    model(
      ARIMA( ~ pdq() + PDQ(0, 0, 0) + xreg(fourier(period = "1 year", K = i))),
    )
  fit_aicc <- glance(fit)$AICc |> mean() #this is silly, but let's just use the mean AICc for all the sites.  It doesn't look like choice of K is very consequential anyway.
  
  if(fit_aicc < best_aicc) {
    bestfit <- fit
    best_aicc <- fit_aicc
  } else {
    break
  }
}
bestfit
fc <- forecast(bestfit, test_df)
autoplot(fc, train_df, level = c(95, 99.99))

# Still gives different ARIMA models for different sites, which is weird, but whatever?.

re_fit <- refit(fit, bind_rows(train_df, test_df)) #refit does not work
forecast(re_fit, h = "1 year") |> autoplot(bind_rows(train_df, test_df))
