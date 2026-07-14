# ==============================================================================
# Script: irrigation_water_source.R
# Description: Processes historical USGS quinquennial water extraction records
# ==============================================================================

library(openxlsx)
library(tidyverse)
library(foreign)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
# Specify your local data directory here before running
data_dir = "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# --- PROCESSING DYNAMIC HISTORICAL USGS ARCHIVES ------------------------------
years     <- c(1990, 1995, 2000, 2005, 2010, 2015)
usgs_list <- list()

for (yr in years) {
  file_name <- paste0("irr_water_s_", yr, ".xlsx")
  df_raw    <- read.xlsx(file_name)
  
  # Standardize shifting field schemas used by the USGS across decades
  if (yr == 1990) {
    df_mapped <- df_raw %>% 
      mutate(FIPS = paste0(scode, area), gw = `ir-wgwfr`/`ir-frtot`, sw = `ir-wswfr`/`ir-frtot`)
  } else if (yr == 1995) {
    df_mapped <- df_raw %>% 
      mutate(FIPS = paste0(StateCode, CountyCode), gw = `IR-WGWFr`/`IR-WFrTo`, sw = `IR-WSWFr`/`IR-WFrTo`)
  } else if (yr == 2000) {
    df_mapped <- df_raw %>% 
      mutate(FIPS = FIPS, gw = `IT-WGWFr`/`IT-WFrTo`, sw = `IT-WSWFr`/`IT-WFrTo`)
  } else { # 2005, 2010, 2015 share a unified database nomenclature
    df_mapped <- df_raw %>% 
      mutate(FIPS = FIPS, gw = `IR-WGWFr`/`IR-WFrTo`, sw = `IR-WSWFr`/`IR-WFrTo`)
  }
  
  usgs_list[[as.character(yr)]] <- df_mapped %>%
    mutate(year = yr) %>%
    group_by(FIPS, year) %>%
    summarise(gw = mean(gw, na.rm = TRUE), sw = mean(sw, na.rm = TRUE), .groups = "drop")
}

# --- EXTRAPOLATE HISTORICAL WATER SOURCE MAX VALUES ---------------------------
irr_water_s1 <- bind_rows(usgs_list) %>%
  filter(!is.nan(gw) & !is.nan(sw)) %>%
  group_by(FIPS) %>%
  summarise(gw_max = max(gw), sw_max = max(sw), .groups = "drop") %>%
  as.data.frame()

# --- EXPORT CALCULATED SUMMARY ------------------------------------------------
write.dbf(irr_water_s1, "irr_water_s.dbf")
message("USGS historical water source summaries generated.")