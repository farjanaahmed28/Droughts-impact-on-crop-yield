# ==============================================================================
# Script: gather crop yield.R
# Description: Clean and format annual county-level crop yields from USDA-NASS
# ==============================================================================

library(openxlsx)
library(tidyverse)
library(foreign)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
# Specify your local data directory here before running
data_dir <- "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# --- HELPER FUNCTION FOR INGESTING CROP CSVs ----------------------------------
process_crop_yield <- function(pattern, output_col) {
  files <- list.files(pattern = pattern)
  
  files %>%
    map_dfr(~read.csv(.x)) %>%
    filter(!(County == "OTHER (COMBINED) COUNTIES")) %>%
    select(state = State.ANSI, county = County.ANSI, year = Year, yield_val = Value) %>%
    mutate(
      state  = formatC(state, width = 2, format = "d", flag = "0"),
      county = formatC(county, width = 3, format = "d", flag = "0"),
      FIPS   = paste0(state, county)
    ) %>%
    select(FIPS, year, !!sym(output_col) := yield_val) %>%
    as.data.frame()
}

# --- PROCESS CORN AND SOY DATA ------------------------------------------------
corn_yield <- process_crop_yield("corn_yield", "corn_yield")
soy_yield  <- process_crop_yield("soy_yield", "soy_yield")

# --- EXPORT COMPILED FILES ----------------------------------------------------
write.dbf(corn_yield, "corn_yld.dbf")
write.dbf(soy_yield, "soy_yld.dbf")
message("Crop yield ingestion complete.")
