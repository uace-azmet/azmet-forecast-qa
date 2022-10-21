# Scrape historic data
library(readr)
library(purrr)

# create colnames by matching API data colnames to this: https://ag.arizona.edu/azmet/raw2003.htm
colnames_daily <- c("date_year","date_doy","station_number","temp_air_maxC","temp_air_minC","temp_air_meanC","relative_humidity_max","relative_humidity_min","relative_humidity_mean","vp_deficit_mean","sol_rad_total","precip_total_mm","temp_soil_10cm_maxC","temp_soil_10cm_minC","temp_soil_10cm_meanC","temp_soil_50cm_maxC","temp_soil_50cm_minC","temp_soil_50cm_meanC","wind_spd_mean_mps","wind_vector_magnitude","wind_vector_dir","wind_vector_dir_stand_dev","wind_spd_max_mps","eto_azmet","heat_units_3413C","eto_pen_mon","vp_actual_mean","dwpt_mean")


# create vector of URLs
# 2003 = "https://ag.arizona.edu/azmet/data/0103rd.txt"
# 2004 = "https://ag.arizona.edu/azmet/data/0104rd.txt"
# 2022 = "https://ag.arizona.edu/azmet/data/0122rd.txt"

urls <- 
  paste0("https://ag.arizona.edu/azmet/data/01", formatC(3:20, width = 2, flag = "0"), "rd.txt")

daily_hist <- read_csv(urls, col_names = colnames_daily)

write_csv(daily_hist, "data/daily_hist.csv")
