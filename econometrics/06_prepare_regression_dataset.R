# ==============================================================================
# Script: 03_prepare_regression_dataset.R
# Description: Merges processed panels, fills missing attributes, appends 
#              geographical centroids, and formats variables for estimation.
# ==============================================================================

library(foreign)
library(tidyverse)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
# Specify your local data directory here before running
data_dir <- "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# --- 1. DATA INGESTION --------------------------------------------------------
carea_dr    <- read.dbf("dr_impacted_croparea.dbf")
corn        <- read.dbf("corn_yld.dbf") %>% mutate(FIPS = fips, year = as.factor(year))[cite: 11]
soy         <- read.dbf("soy_yld.dbf") %>% mutate(FIPS = fips, year = as.factor(year))[cite: 11]
ag_dep      <- read.dbf("ag_dep_fips.dbf")
irr_per     <- read.dbf("irr_percent_fin.dbf") %>% mutate(FIPS = fips)[cite: 11]
irr_water_s <- read.dbf("irr_water_s.dbf")

# --- 2. COMPILE MASTER PANEL DATASET ------------------------------------------
# Iteratively reduce datasets down by key identifiers
dataset_list <- list(carea_dr, corn, soy, ag_dep, irr_per, irr_water_s)[cite: 11]
full_data    <- dataset_list %>% reduce(merge, by = c("FIPS", "year"))[cite: 11]

# Fill unobserved ratiometric categories cleanly with zeros
drought_cols <- c("D0Carea_m", "D1Carea_m", "D2Carea_m", "D3Carea_m", "D4Carea_m")[cite: 11]
full_data[drought_cols] <- map_df(full_data[drought_cols], ~replace_na(.x, 0))[cite: 11]

# --- 3. CALCULATE STRUCTURAL REGRESSION FACTOR LEVELS -------------------------
full_data <- full_data %>%
  group_by(FIPS) %>%
  mutate(yeartrend = 1:n()) %>% # Calculate internal linear trend sequence
  ungroup() %>%
  mutate(
    trend       = yeartrend,[cite: 9]
    trend2      = trend^2,[cite: 9]
    farm_dep    = ifelse(farm_dep_1 == 1, "farm_dep", "not_farm_dep"),[cite: 9]
    irr_1       = ifelse(max_irr_h_per > 0.15, 1, 0), # Threshold matching methodology[cite: 9]
    sw_dep_1    = ifelse(sw_max >= 0.5 & irr_1 == 1, 1, 0),[cite: 9]
    gw_dep_1    = ifelse(gw_max >= 0.5 & irr_1 == 1, 1, 0),[cite: 9]
    lcorn_yld   = log(corn_yield + 1),[cite: 9]
    lsoy_yld    = log(soy_yield + 1)[cite: 9]
  )

# Filter dataset to include only counties with valid crop production records[cite: 9]
valid_counties <- full_data %>%
  group_by(FIPS) %>%
  summarise(
    total_corn = sum(corn_yield, na.rm = TRUE),[cite: 9]
    total_soy  = sum(soy_yield, na.rm = TRUE),[cite: 9]
    .groups    = "drop"
  ) %>%
  filter(total_corn > 0 | total_soy > 0)[cite: 9]

full_data <- full_data %>% filter(FIPS %in% valid_counties$FIPS)[cite: 9]

# --- 4. APPEND CENTROIDS FOR CONLEY SE RESTRICTIONS -------------------------
cen  <- read.dbf("Lat_lon_cen_county.dbf") %>% select(FIPS = CNTYIDFP00, lon = Long, lat = Lat)[cite: 11]
final_regression_dataset <- left_join(full_data, cen, by = "FIPS")[cite: 11]

# --- 5. EXPORT FINAL MASTER CACHE --------------------------------------------
write.dbf(as.data.frame(final_regression_dataset), "full_dataset.dbf")[cite: 11]
message("Regression master dataset compiled successfully.")
