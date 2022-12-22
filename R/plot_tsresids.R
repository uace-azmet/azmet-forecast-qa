
#' Model diagnostic plots for timeseries models
#' 
#' A simplified re-implementation of `feasts::gg_tsresiduals()` that uses the
#' `patchwork` package to combine sub-plots for better printing inside .qmd docs
#'
#' @param mdl_df a "mable" produced by `fabletools::model()`
#'
#' @return a patchwork object
plot_tsresids <- function(mdl_df) {
  resid <- residuals(mdl_df, type = "innovation")
  resid_nona <- resid |> drop_na()
  acf <- ACF(resid)
  
  #if there's no non-missing residuals, return an empty plot I guess?
  if(nrow(resid_nona) == 0) return(ggplot())
  
  trace <- 
    ggplot(resid_nona, aes(x = !!index(resid_nona), y = .resid)) + 
    geom_line() + 
    geom_point()
  hist <- 
    ggplot(resid_nona, aes(.resid)) + 
    geom_histogram() +
    geom_rug()
  acf_plot <- autoplot(ACF(resid, .resid, lag_max = 40))
  # acf_plot
  
  trace / (acf_plot + hist)
  
}
# # library(patchwork)
# tar_load(ts_daily, branches = 12)
# mdl_df <- ts_daily[[1]] 
# plot_tsresids(mdl_df)
