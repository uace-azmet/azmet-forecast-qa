# tar_load(db_daily)
# library(lubridate)
# library(arrow)
# library(tidyverse)

make_model_data <- function(db_daily) {
 daily <- open_dataset(db_daily)
 start <- today() - years(5)
 daily <- daily |>
   filter(datetime >= start) |> 
   collect()
 
 # convert to tsibble
 build_tsibble(
   daily,
   key = c(meta_station_id, meta_station_name),
   index = datetime,
   # interval = new_interval(year = 1) #TODO figure out how to get this right
 ) |>
   #make gaps explicit
   fill_gaps(.full = TRUE)
}