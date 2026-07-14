# ==============================================================================
# Script: Ag depended counties.R
# Description: Processes ERS County Typology Codes for agricultural dependence
# ==============================================================================

library(foreign)
library(tidyverse)
library(openxlsx)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
# Specify your local data directory here before running
data_dir <- "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# --- DATA INGESTION & CLEANING ------------------------------------------------
ag_dep_raw <- read.xlsx("ERSCountyTypology2015Edition.xlsx")

# Assign descriptive headers mapping to ERS documentation
# metro_1: Metro-nonmetro status (2013). 0 = Nonmetro, 1 = Metro
# farm_dep_1: Farming 2015 Update indicator (1 = Yes)
# explicit_category: Non-Overlapping Economic Types
colnames(ag_dep_raw) <- c("FIPS", "metro_1", "explicit_category", "farm_dep_1")

# Clean and pad FIPS codes to standard 5-digit strings
ag_dep_fips <- ag_dep_raw %>%
  mutate(FIPS = formatC(as.numeric(FIPS), width = 5, format = "d", flag = "0")) %>%
  select(FIPS, metro_1, explicit_category, farm_dep_1)

# --- EXPORT CLEAN VARIABLES ---------------------------------------------------
write.dbf(as.data.frame(ag_dep_fips), "ag_dep_fips.dbf")
message("Agricultural dependence classification completed.")
