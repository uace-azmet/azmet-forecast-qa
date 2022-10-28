
# azmet-qaqc

<!-- badges: start -->
<!-- badges: end -->

The goal of azmet-qaqc is to create scripts to run QA/QC on AZMet data.

## Repo Structure

- `wrangling/` contains a script for scraping weather data from 2003 onward that isn't available through the API / the `azmetr` package. This should only need to be run once ever.
- `data/` contains the .csv file of the historic data (since 2003)
- `QA/` contains quarto documents of notes / analysis.  `sliding-windows.qmd` is an exploration of a sliding-window quantile approach that is probably not going to work for us.  `azmet-qaqc.qmd` is an exploration of QA by forecasting.
- `renv/` is necessary for the `renv` package to work (see below)

Rendered reports available as well:

- [QA by Forecasting](https://cct-datascience.github.io/azmet-qaqc/QA/azmet-qaqc.html)
- [Sliding Window Quantiles](https://cct-datascience.github.io/azmet-qaqc/docs/sliding-window.html)

## Collaboration guidelines

This project uses [`renv`](https://rstudio.github.io/renv/articles/renv.html) for package management. When opening this repo as an RStudio Project for the first time, `renv` should automatically install itself and prompt you to run `renv::restore()` to install all package dependencies.

To contribute to this project, please create a new branch for your changes and make a pull request. One easy way to do this from within R is with the `usethis` package and the `pr_*` functions. `pr_init("branch-name")` begins a new branch locally, `pr_push()` helps you create a new pull request, and after it is merged you can use `pr_finish()` to clean things up. More about this workflow [here](https://usethis.r-lib.org/articles/pr-functions.html).