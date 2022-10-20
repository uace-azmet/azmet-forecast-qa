
# azmet-qaqc

<!-- badges: start -->
<!-- badges: end -->

The goal of azmet-qaqc is to ...

## Notes

For now, notes are published as markdown [here](azmet-qaqc.md)


## Collaboration guidelines

This project uses [`renv`](https://rstudio.github.io/renv/articles/renv.html) for package managment. When opening this repo as an RStudio Project for the first time, `renv` should automatically install itself and prompt you to run `renv::restore()` to install all package dependencies.

To contribute to this project, please create a new branch for your changes and make a pull request. One easy way to do this from within R is with the `usethis` package and the `pr_*` functions. `pr_init("branch-name")` begins a new branch locally, `pr_push()` helps you create a new pull request, and after it is merged you can use `pr_finish()` to clean things up. More about this workflow [here](https://usethis.r-lib.org/articles/pr-functions.html).