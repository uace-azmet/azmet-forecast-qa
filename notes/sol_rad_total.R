library(azmetr)
library(tidyverse)
library(targets)
library(arrow)
library(fishmethods)
library(lubridate)
library(units)
library(tsibble)

az_solar <- 
  tar_read(db_hourly) |> 
  open_dataset() |> 
  select(meta_station_id, meta_station_name, date_datetime, date_doy, sol_rad_total) |> 
  collect() |> 
  az_add_units() |> 
  #set timezone
  mutate(date_datetime = date_datetime |> force_tz("America/Phoenix") |> round_date(unit = "hours")) |> 
  #just use 2021 for simplicity
  filter(year(date_datetime)==2021) 

# Convert to tsibble, fill gaps, add station info
az_solar_ts <-
  az_solar |> 
  as_tsibble(key = c(meta_station_id, meta_station_name), index = date_datetime) |>
  fill_gaps() |> 
  left_join(azmetr::station_info)



# calculate solar stuff
az_solar_calc <-
  az_solar_ts |> 
  add_column(tz = -7) |> 
  with(data = _, 
  astrocalc4r(
    day = mday(date_datetime),
    month =  month(date_datetime),
    year = year(date_datetime),
    hour = hour(date_datetime),
    timezone = tz,
    lat = latitude,
    lon = longitude,
    withinput = FALSE,
    seaorland = "continental"
  )
)

#join it up
az_solar_df <-
  bind_cols(az_solar_ts, az_solar_calc) |> 
  select(
    meta_station_id,
    meta_station_name,
    date_datetime,
    date_doy,
    sol_rad_total,
    latitude,
    longitude,
    zenith,
    daylight,
    par = PAR
  ) |> 
  #set units
  mutate(par = set_units(par, "lux")) 


#convert
sunlight <-  set_units(0.0079, "(W/m^2) / Lux") # approximate. https://physics.stackexchange.com/questions/135618/rm-lux-and-w-m2-relationship

az_solar_df |>
  mutate(par = par*sunlight) |>
  mutate(par = set_units(par, "MJ/m^2/h") * set_units(1, "hr")) |> 

  filter(date_doy == 9, year(date_datetime)== 2021) |> 
  ggplot(aes(x = date_datetime)) +
  geom_line(aes(y = sol_rad_total)) +
  geom_line(aes(y = par), color = "red") +
  facet_wrap(~meta_station_id)

#PAR is too small of a slice of the solar radiation measured to be helpful.  Ugh. need to calculate for a wider range of wavelenghts.

# this version uses the solar constant to estimate solar radiation *outside* the atmosphere
zenith_to_sol_rad <- function(zenith){
  foo <-  function(zenith) {
    
    #convert to radians
    zenith_rad <- zenith * pi / 180
    #cos zenith angle
    cosz <- cos(zenith_rad)
    #assume 0 radiation when angle ≥ 90
    if(zenith >= 90) {
      radiation <- 0
    } else {
      #multiply by "solar constant" 
      radiation <-  cosz * 1388 #W/m^2
    }
    radiation
  }
  radiation <- purrr:::map_dbl(zenith, foo)
  
  set_units(radiation, "W/m^2")
}

az_solar_df <-
  az_solar_df |> 
  mutate(r_pot = (zenith_to_sol_rad(zenith) * set_units(1, "hr")) |> set_units("MJ/m^2") )

az_solar_df |> 
  filter(date_doy == 300, year(date_datetime)== 2021) |>
  ggplot(aes(x = date_datetime)) +
  geom_line(aes(y = sol_rad_total)) +
  geom_line(aes(y = r_pot), color = "red") +
  facet_wrap(~meta_station_id)

#check against daily data

az_solar_daily <- 
  az_solar_df |> 
  as_tibble() |> 
  mutate(date = date(date_datetime)) |>
  group_by(date, meta_station_id, meta_station_name) |> 
  summarize(r_pot = sum(r_pot))

daily <- 
  tar_read(db_daily) |> open_dataset() |> 
  select(meta_station_id, meta_station_name, datetime, date_doy, sol_rad_total) |> 
 #just use 2021 for simplicity
  filter(year(datetime)==2021) |> 
  collect() |> 
  az_add_units() |> 
  rename(date = datetime)

full_join(az_solar_daily, daily) |> 
  ggplot(aes(x= date, color = meta_station_id)) +
  geom_line(aes(y = sol_rad_total)) +
  geom_line(aes(y = r_pot), color = "red") +
  facet_wrap(~meta_station_id)

#not useful because doesn't include atmosphere.
