# ==============================================================================
# Script: irrigated_harvested_cropland.R
# Description: Generates maximum baseline historical irrigation percentages
# ==============================================================================

library(openxlsx)
library(tidyverse)
library(foreign)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
# Specify your local data directory here before running
data_dir <- "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# --- CLEAN HARVESTED IRRIGATION DATASET ----------------------------------------
irr_cropland <- read.csv("irrigated_harvested_cropland.csv")

irr_clean <- irr_cropland %>%
  filter(!is.na(County.ANSI)) %>%
  select(state = State.ANSI, county = County.ANSI, year = Year, irr_h_cropland = Value) %>%
  mutate(
    state          = formatC(state, width = 2, format = "d", flag = "0"),
    county         = formatC(county, width = 3, format = "d", flag = "0"),
    FIPS           = paste0(state, county),
    irr_h_cropland = as.numeric(gsub(",", "", irr_h_cropland))
  ) %>%
  select(FIPS, year, irr_h_cropland)

# --- CLEAN TOTAL CROP FOOTPRINT DATASET ---------------------------------------
total_cropland <- read.csv("total_harvested_cropland_for _irr.csv")

total_clean <- total_cropland %>%
  filter(!is.na(County.ANSI)) %>%
  select(state = State.ANSI, county = County.ANSI, year = Year, irr_t_cropland = Value) %>%
  mutate(
    state          = formatC(state, width = 2, format = "d", flag = "0"),
    county         = formatC(county, width = 3, format = "d", flag = "0"),
    FIPS           = paste0(state, county),
    irr_t_cropland = as.numeric(gsub(",", "", irr_t_cropland))
  ) %>%
  select(FIPS, year, irr_t_cropland)

# --- COMPUTE HISTORICAL MAXIMUM RATIO -----------------------------------------
irr_percent_fin <- left_join(irr_clean, total_clean, by = c("FIPS", "year")) %>%
  mutate(irr_h_per = irr_h_cropland / irr_t_cropland) %>%
  group_by(FIPS) %>%
  summarise(max_irr_h_per = max(irr_h_per, na.rm = TRUE), .groups = "drop") %>%
  mutate(max_irr_h_per = ifelse(max_irr_h_per == -Inf, NA, max_irr_h_per)) %>%
  as.data.frame()

# --- EXPORT CALCULATED SUMMARY ------------------------------------------------
write.dbf(irr_percent_fin, "irr_percent_fin.dbf")
message("County-level maximum irrigation ratios calculated.")