# ==============================================================================
# Script: 04_conley_spatial_cutoff.R
# Description: Evaluates geographic distance combinations across centroids to
#              calculate lag limits for Conley standard error structures.
# ==============================================================================

library(tidyverse)
library(foreign)
library(geosphere)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
data_dir <- "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# --- 1. SET SPATIAL COORDINATES -----------------------------------------------
lat_lon <- read.dbf("Lat_lon_cen_county.dbf") %>% 
  select(FIPS = CNTYIDFP00, lat = Lat, lon = Long)[cite: 10, 11]

# Isolate unique coordinate combinations
coords_matrix <- lat_lon %>% select(lon, lat)[cite: 10]

# --- 2. CALCULATE PAIRWISE HAVERSINE COMBINATIONS -----------------------------
# Generate combinatoric indexes across all rows
row_pairs <- combn(nrow(coords_matrix), 2)[cite: 10]

# Create data frames representing matching pairs
p1_coords <- coords_matrix[row_pairs[1, ], ]
p2_coords <- coords_matrix[row_pairs[2, ], ]

# Calculate distances in meters using spherical law of cosines (Haversine)[cite: 10]
pairwise_distances <- distHaversine(p1_coords, p2_coords)[cite: 10]

# --- 3. COMPUTE MATRIX CUTOFF CRITERIA -----------------------------------------
# Re-link combinations back to FIPS codes to evaluate max-min distribution limits
spatial_gaps <- tibble(
  xFIPS = lat_lon$FIPS[row_pairs[1, ]],
  dist  = pairwise_distances[cite: 10]
)

# Extract maximum contiguous neighbor threshold to anchor your 1380 km window[cite: 9, 10]
county_min_bounds <- spatial_gaps %>%
  group_by(xFIPS) %>%
  summarise(min_dist = min(dist, na.rm = TRUE), .groups = "drop")[cite: 10]

max_neighbor_gap_km <- max(county_min_bounds$min_dist, na.rm = TRUE) / 1000[cite: 10]

print(paste0("Maximum isolated distance to nearest neighboring county: ", round(max_neighbor_gap_km, 2), " km"))