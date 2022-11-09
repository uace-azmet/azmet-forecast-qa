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
    "feasts",
    "readxl"
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
  daily_hist = read_wrangle_hist(hist_file),
  daily_recent = get_daily_recent(daily_hist),
  daily = update_daily(daily_hist, daily_recent), 
  daily_train = daily |> filter(datetime < max(datetime)), 
  daily_test = daily |> filter(datetime == max(datetime)),
  
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

