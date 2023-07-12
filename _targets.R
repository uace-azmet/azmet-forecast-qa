# Follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline 

# Load packages required to define the pipeline:
library(targets)
# library(crew) #for parallel workers
library(tarchetypes)
library(arrow)

# Set target options:
tar_option_set(
  # define packages needed for the workflow:
  packages = c(
    "tibble",
    "tidyverse",
    "azmetr",
    "tsibble",
    "quarto",
    "lubridate",
    "fable",
    "fabletools",
    "feasts",
    "readxl",
    "arrow",
    "patchwork",
    "glue",
    "pins",
    "urca"
  ), 
  seed = 659,
  # controller = crew_controller_local(workers = 4),
  format = "rds" # default storage format
)

# Source the R scripts in the R/ folder with your custom functions:
tar_source()

# Define targets:
tar_plan(

  # Read and wrangle data ---------------------------------------------------
  tar_file(legacy_daily_file, "data/daily_hist.csv"),
  tar_target(
    legacy_daily, #up to 2003
             read_wrangle_hist(legacy_daily_file),
    format = "parquet",
    deployment = "main"
  ), 
  #get data from 2003 to 2020
  tar_target(
    daily, 
    update_daily_hist(legacy_daily),
    cue = tar_cue("always"),
    format = "parquet",
    deployment = "main"
  ), 
  
  tar_file(metadata_file, "data/azmet-data-metadata.xlsx"),
  needs_qa_daily = needs_qa(metadata_file, "daily"),

  # Modeling ----------------------------------------------------------------
  # Limit forecast-based validation to just variables that are appropriate for
  # this kind of modeling.
  tar_target(
    forecast_qa_vars,
    needs_qa_daily[!needs_qa_daily %in% c(
      "wind_vector_dir", #polar coords
      "sol_rad_total", #zero-inflated, ≥0
      "precip_total_mm", #zero-inflated, ≥0
      "wind_vector_dir_stand_dev" #≥0
    )]
  ),

  # #subset for testing
  # tar_target(
  #   forecast_qa_vars,
  #   c("temp_soil_10cm_maxC", "temp_air_meanC")
  # ),
  
  # Fit timeseries model (once every 60 days)
  tar_target(
    models_daily,
    fit_model_daily(daily, forecast_qa_vars),
    pattern = map(forecast_qa_vars),
    iteration = "list",
    cue = tarchetypes::tar_cue_age(
      name = models_daily,
      age = as.difftime(60, units = "days"),
      depend = FALSE #don't re-run just because `daily` is invalidated
    )
  ),
  
  # Model Diagnostics 
  
  # TODO: Currently, this target just makes diagnostic plots
  # for Tucson, but would be good to eventually inspect other stations since
  # different ARIMA models are fit for each station.  Eventually could have a
  # separate, static report that is published with plots and other model
  # diagnostics for each station.
  
  tar_target(
    resid_daily,
    plot_tsresids(models_daily |> filter(meta_station_id == "az01")) +
      patchwork::plot_annotation(title = forecast_qa_vars),
    pattern = map(models_daily, forecast_qa_vars),
    iteration = "list"
  ),
  
  # Forecasting -------------------------------------------------------------
  # re-fit model with data up to yesterday, forecast today, return a tibble
  tar_target(
    fc_daily,
    forecast_daily(models_daily, daily, forecast_qa_vars),
    pattern = map(models_daily, forecast_qa_vars),
    iteration = "vector",
    format = "parquet"
  ),
  
  # add forecast to previous forecasts
  
  tar_target(
    pin_fc,
    pin_forecast(fc_daily),
    deployment = "main"
  ),

  # update datasets on Connect for report to use
  tar_target(
    daily_pin,
    pin_daily(),
    deployment = "main",
    cue = tar_cue("always")
  ),
  
  tar_target(
    hourly_pin,
    pin_hourly(),
    deployment = "main",
    cue = tar_cue("always")
  ),
  
  # Reports -----------------------------------------------------------------
  tar_quarto(readme, "README.qmd")
)
