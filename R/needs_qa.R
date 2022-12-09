# library(readxl)
# library(dplyr)

needs_qa <- function(metadata_file, sheet) {
  meta <- read_excel(metadata_file, sheet = sheet)
  needs_qa <- meta |> filter(type == "measured") |> pull(variable)
  needs_qa
}
