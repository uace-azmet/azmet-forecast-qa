# README

<!-- README.md is generated from README.qmd. Please edit that file -->

# azmet-qaqc

<!-- badges: start -->

[![targets-workflow](https://github.com/cct-datascience/azmet-qaqc/actions/workflows/targets.yaml/badge.svg)](https://github.com/cct-datascience/azmet-qaqc/actions/workflows/targets.yaml)
<!-- badges: end -->

This repository contains code to generate a dataset for doing timeseries
forecast-based quality assurance checks for
[AZMET](https://ag.arizona.edu/azmet/) meterological data. Daily
resolution data is accessed via the
[`azmetr`](https://github.com/cct-datascience/azmetr) R package. A
timeseries model is fit to all but the last day of data and a forecast
is made for the last day. This is then uploaded to a Posit Connect
server and used downstream by a [validation
report](https://github.com/cct-datascience/azmet-qa-dashboard).

## Reproducibility

This project uses
[`renv`](https://rstudio.github.io/renv/articles/renv.html) for package
management. When opening this repo as an RStudio Project for the first
time, `renv` should automatically install itself and prompt you to run
`renv::restore()` to install all package dependencies.

This project uses the [`targets`
package](https://docs.ropensci.org/targets/) for workflow management.
Run `targets::tar_make()` from the console to run the workflow and
reproduce all results. To reproduce the last step that updates the
forecast dataset “pin” on Connect, you’ll need to create a .Renviron
file with

    CONNECT_SERVER="https://viz.datascience.arizona.edu/"
    CONNECT_API_KEY=<your API key>

And you must have permission to publish to that pin. Without this setup,
other targets should still run and you can inspect results of each step
with `tar_read()`.

**Targets workflow:**

Attaching package: ‘arrow’

The following object is masked from ‘package:utils’:

    timestamp

``` mermaid
graph LR
  subgraph legend
    direction LR
    x0a52b03877696646([""Outdated""]):::outdated --- x7420bd9270f8d27d([""Up to date""]):::uptodate
    x7420bd9270f8d27d([""Up to date""]):::uptodate --- x5b3426b4c7fa7dbc([""Started""]):::started
    x5b3426b4c7fa7dbc([""Started""]):::started --- xbf4603d6c2c2ad6b([""Stem""]):::none
    xbf4603d6c2c2ad6b([""Stem""]):::none --- x70a5fa6bea6f298d[""Pattern""]:::none
    x70a5fa6bea6f298d[""Pattern""]:::none --- xf0bce276fe2b9d3e>""Function""]:::none
  end
  subgraph Graph
    direction LR
    x3d7b2a2ab5636113(["metadata_file"]):::uptodate --> xdfae9ea4e5207cef(["needs_qa_daily"]):::uptodate
    x06ab7116eed66f15>"needs_qa"]:::uptodate --> xdfae9ea4e5207cef(["needs_qa_daily"]):::uptodate
    xdfae9ea4e5207cef(["needs_qa_daily"]):::uptodate --> x601d3b0e7d261371(["forecast_qa_vars"]):::uptodate
    x1920bdb737e11d2e(["legacy_daily_file"]):::uptodate --> xff9b736edef41c8b(["legacy_daily"]):::uptodate
    x842666df821db265>"read_wrangle_hist"]:::uptodate --> xff9b736edef41c8b(["legacy_daily"]):::uptodate
    x6233d5fdb54d5242(["daily"]):::outdated --> xdd96ec4b0bb5ab6b["fc_daily"]:::outdated
    x4bc7352f98499683>"forecast_daily"]:::uptodate --> xdd96ec4b0bb5ab6b["fc_daily"]:::outdated
    x601d3b0e7d261371(["forecast_qa_vars"]):::uptodate --> xdd96ec4b0bb5ab6b["fc_daily"]:::outdated
    x4d3c4dcfeadc796d["models_daily"]:::uptodate --> xdd96ec4b0bb5ab6b["fc_daily"]:::outdated
    x601d3b0e7d261371(["forecast_qa_vars"]):::uptodate --> x0bb4ecca77d3d4a0["resid_daily"]:::uptodate
    x4d3c4dcfeadc796d["models_daily"]:::uptodate --> x0bb4ecca77d3d4a0["resid_daily"]:::uptodate
    x10e889bcd8b0fd60>"plot_tsresids"]:::uptodate --> x0bb4ecca77d3d4a0["resid_daily"]:::uptodate
    x6233d5fdb54d5242(["daily"]):::outdated --> x4d3c4dcfeadc796d["models_daily"]:::uptodate
    x1f5572089e80d919>"fit_model_daily"]:::uptodate --> x4d3c4dcfeadc796d["models_daily"]:::uptodate
    x601d3b0e7d261371(["forecast_qa_vars"]):::uptodate --> x4d3c4dcfeadc796d["models_daily"]:::uptodate
    xdd96ec4b0bb5ab6b["fc_daily"]:::outdated --> x8f5c47b9b7da7e75(["pin_fc"]):::outdated
    x82c22abbb211b5ee>"pin_forecast"]:::uptodate --> x8f5c47b9b7da7e75(["pin_fc"]):::outdated
    xff9b736edef41c8b(["legacy_daily"]):::uptodate --> x6233d5fdb54d5242(["daily"]):::outdated
    x8b3096a190996662>"update_daily_hist"]:::uptodate --> x6233d5fdb54d5242(["daily"]):::outdated
    x6e52cb0f1668cc22(["readme"]):::started --> x6e52cb0f1668cc22(["readme"]):::started
  end
  classDef outdated stroke:#000000,color:#000000,fill:#78B7C5;
  classDef uptodate stroke:#000000,color:#ffffff,fill:#354823;
  classDef started stroke:#000000,color:#000000,fill:#DC863B;
  classDef none stroke:#000000,color:#000000,fill:#94a4ac;
  linkStyle 0 stroke-width:0px;
  linkStyle 1 stroke-width:0px;
  linkStyle 2 stroke-width:0px;
  linkStyle 3 stroke-width:0px;
  linkStyle 4 stroke-width:0px;
  linkStyle 24 stroke-width:0px;
```

## Repo Structure

``` r
fs::dir_tree(recurse = 1)
```

    .
    ├── R
    │   ├── fit_model_daily.R
    │   ├── forecast_daily.R
    │   ├── needs_qa.R
    │   ├── pin_forecast.R
    │   ├── plot_tsresids.R
    │   ├── read_wrangle_hist.R
    │   └── update_daily_hist.R
    ├── README.md
    ├── README.qmd
    ├── README.rmarkdown
    ├── _targets
    │   ├── meta
    │   ├── objects
    │   └── user
    ├── _targets.R
    ├── _targets_packages.R
    ├── azmet-qaqc.Rproj
    ├── data
    │   ├── azmet-data-metadata.xlsx
    │   └── daily_hist.csv
    ├── notes
    │   ├── ARIMA.html
    │   ├── ARIMA.qmd
    │   ├── ARIMA_files
    │   ├── QA-report.qmd
    │   ├── azmet-qaqc.qmd
    │   ├── gams.qmd
    │   ├── references.bib
    │   └── sliding-window.qmd
    ├── renv
    │   ├── activate.R
    │   ├── library
    │   ├── sandbox
    │   ├── settings.dcf
    │   ├── settings.json
    │   └── staging
    ├── renv.lock
    ├── run.R
    └── wrangling
        └── scrape_historic.R

- `R/` contains functions used in the `targets` pipeline.
- `_targets` is generated by `targets::tar_make()` and only the metadata
  of the targets pipeline is on GitHub.
- `_targets.R` defines a `targets` workflow
- `_targets_packages.R` is generated by `targets::tar_renv()`
- `data/` contains the .csv file of the historic data (since 2003)
- `notes/` contains quarto documents of notes / analysis.
  `sliding-windows.qmd` is an exploration of a sliding-window quantile
  approach that is probably not going to work for us. `azmet-qaqc.qmd`
  is an exploration of QA by forecasting.
- `renv/` and `renv.lock` are necessary for the `renv` package to work
  (see above)
- `run.R` is for conveniently running `tar_make()` as a background job.
  Created by `targets::use_targets()`
- `wrangling/` contains a script for scraping weather data from 2003
  onward that isn’t available through the API / the `azmetr` package.
  This should only need to be run once ever.

## Collaboration guidelines

To contribute to this project, please create a new branch for your
changes and make a pull request. One easy way to do this from within R
is with the `usethis` package and the `pr_*` functions.
`pr_init("branch-name")` begins a new branch locally, `pr_push()` helps
you create a new pull request, and after it is merged you can use
`pr_finish()` to clean things up. More about this workflow
[here](https://usethis.r-lib.org/articles/pr-functions.html).
