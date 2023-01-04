# Follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline 

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

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
    "patchwork"
  ), 
  format = "rds" # default storage format
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone):
future::plan(future.callr::callr)

# Source the R scripts in the R/ folder with your custom functions:
tar_source()


# Define targets:
tar_plan(

  # Read and wrangle data ---------------------------------------------------
  tar_file(legacy_daily_file, "data/daily_hist.csv"),
  tar_target(legacy_daily, #up to 2003
             read_wrangle_hist(legacy_daily_file),
             deployment = "main"), 
  tar_target(db_daily_init, #up to october 2022
             update_daily_hist(legacy_daily),
             deployment = "main"), 
  tar_target(db_daily, 
             update_daily(db_daily_init), #also writes to data/daily
             #This target becomes invalid if it hasn't been run for a day
             cue = tarchetypes::tar_cue_age(
               name = db_daily,
               age = as.difftime(1, units = "days") 
             ),
             format = "file",
             deployment = "main"), #don't run on parallel worker
  

  #hourly
  hourly_start = "2020-12-30 00",
  tar_target(db_hourly_init,
    init_hourly(hourly_start),
    deployment = "main"),
  tar_target(
    db_hourly,
    update_hourly(db_hourly_init),
    #This target becomes invalid if it hasn't been run for a day
    cue = tarchetypes::tar_cue_age(
      name = db_hourly,
      age = as.difftime(1, units = "days")
    ),
    format = "file",
    deployment = "main" #don't run on parallel workers
  ),
  
  tar_file(metadata_file, "data/azmet-data-metadata.xlsx"),
  needs_qa_daily = needs_qa(metadata_file, "daily"),
  needs_qa_hourly = needs_qa(metadata_file, "hourly"),

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
  
  # # #subset for testing
  # tar_target(
  #   forecast_qa_vars,
  #   c("relative_humidity_max", "temp_air_meanC")
  # ),
  
  #target for training data for models that only gets invalidated once per year
  #so that model is not re-fit every day.
  tar_target(
    training_daily,
    make_training_daily(db_daily, forecast_qa_vars)
  ),
  
  # Fit timeseries model (once a year)
  tar_target(
    models_daily,
    fit_model_daily(training_daily, forecast_qa_vars),
    pattern = map(forecast_qa_vars),
    iteration = "list"
  ),
  
  #do some model diagnostics.  This just does them for Tucson, but would be good
  #to eventually inspect some other stations since different ARIMA models are
  #best fits for different stations apparently
  tar_target(
    resid_daily,
    plot_tsresids(models_daily |> filter(meta_station_id == "az01")) +
      patchwork::plot_annotation(title = forecast_qa_vars),
    pattern = map(models_daily, forecast_qa_vars),
    iteration = "list"
  ),
  
  # Forecasting -------------------------------------------------------------
  # re-fit model with data up to yesterday, forecast today.
  tar_target(
    fc_daily,
    forecast_daily(models_daily, db_daily, forecast_qa_vars),
    pattern = map(models_daily, forecast_qa_vars),
    iteration = "vector"
  ),

  # Reports -----------------------------------------------------------------
  #TODO: move some of the long-running code in the report to targets?
  tar_quarto(report, "docs/QA-report.qmd"),
  tar_quarto(readme, "README.qmd")
  
)
