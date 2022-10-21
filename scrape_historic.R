# Scrape historic data
library(tidyverse)
library(lubridate)

# create colnames by matching API data colnames to this: https://ag.arizona.edu/azmet/raw2003.htm
colnames_daily <- c("date_year","date_doy","station_number","temp_air_maxC","temp_air_minC","temp_air_meanC","relative_humidity_max","relative_humidity_min","relative_humidity_mean","vp_deficit_mean","sol_rad_total","precip_total_mm","temp_soil_10cm_maxC","temp_soil_10cm_minC","temp_soil_10cm_meanC","temp_soil_50cm_maxC","temp_soil_50cm_minC","temp_soil_50cm_meanC","wind_spd_mean_mps","wind_vector_magnitude","wind_vector_dir","wind_vector_dir_stand_dev","wind_spd_max_mps","eto_azmet","heat_units_3413C","eto_pen_mon","vp_actual_mean","dwpt_mean")

# station name lookup table, also existing station IDs
station_names <- 
  tribble(~station_number, ~meta_station_name,
          1 , "Tucson       ",
          2 , "Yuma Valley  ",
          3 , "Yuma Mesa    ",
          4 , "Safford      ",
          5 , "Coolidge     ",
          6 , "Maricopa     ",
          7 , "Aguila       ",
          8 , "Parker       ",
          9 , "Bonita       ",
          10, "Citrus Farm  ",
          11, "Litchfield   ",
          12, "Phx. Greenway",
          13, "Marana       ",
          14, "Yuma N. Gila ",
          15, "Phx. Encanto ",
          16, "Eloy         ",
          17, "Dateland     ",
          18, "Scottsdale   ",
          19, "Paloma       ",
          20, "Mohave       ",
          21, "Laveen         ",
          22, "Queen Creek    ",
          23, "Harquahala     ",
          24, "Roll           ",
          25, "Ciudad Obregon ",
          26, "Buckeye        ",
          27, "Desert Ridge   ",
          28, "Mohave #2      ",
          29, "Mesa           ",
          30, "Flagstaff     ",
          31, "Prescott ",
          32, "Payson",
          33, "Bowie",
          34, "Kansas Settlement",
          35, "Parker-2    ",
          36, "Yuma South",
          37, "San Simon",
          38, "Sahuarita"
  ) |> 
  mutate(meta_station_name = str_trim(meta_station_name))



# create vector of URLs
# 2003 = "https://ag.arizona.edu/azmet/data/0103rd.txt"
# 2004 = "https://ag.arizona.edu/azmet/data/0104rd.txt"
# 2022 = "https://ag.arizona.edu/azmet/data/0122rd.txt"

urls <- 
  expand_grid(
  stations = station_names$station_number,
  years = 3:20
) |> 
  mutate(across(everything(), \(x) formatC(x, width = 2, flag = "0"))) |> 
  glue::glue_data("https://ag.arizona.edu/azmet/data/{stations}{years}rd.txt")

#read all files, skipping missing URLs
read_csv_safe <- possibly(read_csv, NULL)

daily_list <-
  map(urls,
      function(x){
        read_csv_safe(
          x,
          col_names = colnames_daily,
          col_types = cols(.default = col_number())
        )
      }
  )

daily_hist <- bind_rows(daily_list)

# add station names and IDs

daily_hist <- 
  daily_hist |> 
  mutate(meta_station_id = paste0("az", formatC(station_number, width = 2, flag = "0")))


daily_hist <- 
  left_join(daily_hist, station_names, by = "station_number") |> 
  select(-station_number)

# make datetime column
daily_hist <- daily_hist |> 
  mutate(datetime = make_date(year = date_year), .after = date_doy)
yday(daily_hist$datetime) <- daily_hist$date_doy

# Write to csv
write_csv(daily_hist, "data/daily_hist.csv")
