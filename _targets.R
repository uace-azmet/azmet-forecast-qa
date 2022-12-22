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
    "arrow"
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
  
  daily = make_model_data(db_daily), #just use the past 5 years for modeling for now
  daily_train = daily |> filter(datetime < max(datetime)),
  daily_test = daily |> filter(datetime == max(datetime)),
  
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

  ts_sol_rad = fit_ts_sol_rad(daily_train),
  # ts_temp = ,
  # ts_precip = ,

  # Forecasting -------------------------------------------------------------

  fc_sol_rad = forecast_sol_rad(ts_sol_rad, daily_test),
  # fc_remp = ,
  # fc_precip = ,

  # Reports -----------------------------------------------------------------
  tar_quarto(report, "docs/report.qmd"),
  tar_quarto(readme, "README.qmd")
  
)

