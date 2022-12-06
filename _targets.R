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
  legacy_daily = read_wrangle_hist(legacy_daily_file), #up to 2003
  db_daily_init = update_daily_hist(legacy_daily), #up to october 2022
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
  
  #hourly
  hourly_start = "2020-12-30 00",
  tar_target(
    db_hourly_init,
    init_hourly(hourly_start)
  ),
  tar_target(
    db_hourly,
    update_hourly(db_hourly_init),
    #This target becomes invalid if it hasn't been run for a day
    cue = tarchetypes::tar_cue_age(
      name = db_hourly,
      age = as.difftime(1, units = "days")
    ),
    format = "file"
  ),
  
  tar_file(metadata_file, "data/azmet-data-metadata.xlsx"),
  needs_qa_daily = needs_qa(metadata_file, "daily"),
  needs_qa_hourly = needs_qa(metadata_file, "hourly"),

  # Modeling ----------------------------------------------------------------

  #TODO: need to transform variables
  tar_target(
    ts_daily,
    fit_ts_daily(db_daily, needs_qa_daily),
    pattern = map(needs_qa_daily),
    iteration = "list"
  ),
  
  tar_target(
    resid_daily,
    gg_tsresiduals(ts_daily |> filter(meta_station_id == "az01")) +
      labs(title = needs_qa_daily),
    pattern = map(ts_daily, needs_qa_daily), 
    iteration = "list"
  ),
  
  # Forecasting -------------------------------------------------------------
  tar_target(
    fc_daily,
    forecast_daily(ts_daily, db_daily, needs_qa_daily),
    pattern = map(ts_daily, needs_qa_daily),
    iteration = "vector"
  ),

  # Reports -----------------------------------------------------------------
  #TODO: move some of the long-running code in the report to targets?
  tar_quarto(report, "docs/report.qmd"),
  tar_quarto(readme, "README.qmd")
  
)
