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
  legacy_daily = read_wrangle_hist(legacy_daily_file), #up to 2003
  past_daily = update_daily_hist(legacy_daily), #up to october 2022
  tar_target(db_daily_init, write_daily(past_daily)),
  tar_target(
    db_daily, 
    update_daily(db_daily_init), #also writes to data/daily
    #This target becomes invalid if it hasn't been run for a day
    cue = tarchetypes::tar_cue_age(
      name = db_daily,
      age = as.difftime(1, units = "days") 
    ),
    format = "file" #because it returns a filepath?
  ), 
  daily = make_model_data(db_daily), #just use the past 5 years for modeling for now
  daily_train = daily |> filter(datetime < max(datetime)),
  daily_test = daily |> filter(datetime == max(datetime)),

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

