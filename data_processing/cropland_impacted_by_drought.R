# ==============================================================================
# Script: cropland_impacted_by_drought.R
# Description: Extracts ratiometric county cropland drought exposure from NetCDFs
# Replaces: Manual reclassification loops and desktop ArcGIS Zonal Statistics
# ==============================================================================

library(sf)
library(terra)
library(exactextractr)
library(tidyverse)
library(foreign)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
# Specify your local data directory here before running
data_dir <- "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# Define drought classes based on USDM thresholds matrix c(from, to, value)
drought_classes <- list(
  "D4" = c(-20,  -5.0, 1),
  "D3" = c(-4.9, -4.0, 1),
  "D2" = c(-3.9, -3.0, 1),
  "D1" = c(-2.9, -2.0, 1),
  "D0" = c(-1.9, -1.0, 1)
)

# Load County/Cropland Vector Geometry (Point to your shapefile)
counties_sf <- st_read("totalcropland_dr_cropland.shp") %>% 
  st_transform(crs = 3395) # Target projection: World Mercator (EPSG:3395)

# --- RASTER EXTRACTION & RE-PROJECTION -------------------------------------
nc_files <- list.files(pattern = "\\.nc$")
extracted_list <- list()

for (file in nc_files) {
  r_raw <- rast(file, subds = "palmer_drought_severity_index")
  r_round <- round(r_raw, 1)
  
  # Extract temporal metadata from standard gridMET filename strings
  date_str <- substr(file, 23, 30)
  f_year   <- substr(date_str, 1, 4)
  f_month  <- substr(date_str, 5, 6)
  f_day    <- substr(date_str, 7, 8)
  
  for (d_level in names(drought_classes)) {
    bounds <- drought_classes[[d_level]]
    
    # Reclassify to binary layer
    rc_matrix <- matrix(c(bounds[1], bounds[2], bounds[3]), ncol = 3, byrow = TRUE)
    r_binned  <- classify(r_round, rc_matrix, others = NA)
    r_projected <- project(r_binned, "EPSG:3395")
    
    # R Native Zonal Statistics Alternative to ArcGIS
    # exact_extract('mean') calculates the average coverage fraction of drought pixels
    zonal_stats <- exact_extract(r_projected, counties_sf, 'mean', progress = FALSE)
    
    temp_df <- tibble(
      FIPS    = counties_sf$CNTYIDFP00,
      value   = replace_na(zonal_stats, 0),
      d_class = d_level,
      year    = f_year,
      month   = f_month,
      day     = f_day
    )
    
    extracted_list[[length(extracted_list) + 1]] <- temp_df
  }
}

# --- COMBINE AND COMPUTE ANNUAL SKELETON PANEL --------------------------------
all_drought_data <- bind_rows(extracted_list)

annual_drought_summary <- all_drought_data %>%
  group_by(FIPS, year, d_class) %>%
summarise(
  area_sum  = sum(value, na.rm = TRUE),
  area_mean = mean(value, na.rm = TRUE),
  .groups   = "drop"
) %>%
  pivot_wider(
    id_cols     = c(FIPS, year),
    names_from  = d_class,
    values_from = c(area_sum, area_mean),
    names_glue  = "{d_class}Carea_{.value}"
  ) %>%
  rename_with(~ str_replace(., "area_sum", "s")) %>%
rename_with(~ str_replace(., "area_mean", "m"))

# Build comprehensive cross-section panel backbone (1990-2019)
total_cropland <- counties_sf %>%
  st_drop_geometry() %>%
  select(FIPS = CNTYIDFP00, t_cropland = AREA)

master_panel <- crossing(
  FIPS = unique(total_cropland$FIPS),
  year = as.character(1990:2019)
)

final_panel <- master_panel %>%
  left_join(annual_drought_summary, by = c("FIPS", "year")) %>%
mutate(across(everything(), ~ replace_na(., 0)))

# --- EXPORT CLEAN MATRIX ------------------------------------------------------
write.dbf(as.data.frame(final_panel), "dr_impacted_croparea.dbf")
message("Spatial extraction pipeline executed successfully.")