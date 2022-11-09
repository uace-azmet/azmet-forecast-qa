# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # Load other packages as needed. # nolint

# Set target options:
tar_option_set(
  packages = c(
    "tibble",
    "tidyverse",
    "azmetr",
    "tsibble",
    "quarto",
    "lubridate",
    "fable",
    "fabletools",
    "feasts"
  ), 
  format = "rds" # default storage format
  # Set other options as needed.
)

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone):
future::plan(future.callr::callr)

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# source("other_functions.R") # Source other scripts as needed. # nolint

# Replace the target list below with your own:
tar_plan(

# Read and wrangle data ---------------------------------------------------
  tar_file(hist_file, "data/daily_hist.csv"),
  daily_hist = read_wrangle_hist(hist_file), #up to 2003
  daily_recent = update_daily_hist(daily_hist), #up to october 2022
  # tar_target(data_daily, write_daily_recent(daily_recent), format = "file"),
  daily = update_daily(daily_recent),
  # tar_target(daily, update_daily(data_daily), format = "file"), #also writes to data/daily
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

