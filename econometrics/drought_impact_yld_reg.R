# ==============================================================================
# Script: 05_econometric_estimations.R
# Description: Estimates high-dimensional panel data specifications using spatial
#              Conley standard errors and exports corresponding TeX code.
# ==============================================================================

library(fixest)
library(tidyverse)
library(foreign)

# --- ENVIRONMENT INITIALIZATION -----------------------------------------------
data_dir <- "SET_YOUR_DATA_DIRECTORY_PATH" 
setwd(data_dir)

# Load clean master dataset panel
data <- read.dbf("full_dataset.dbf", as.is = TRUE)[cite: 9]

# --- 1. DICTIONARY DEFINITIONS FOR LATEX RE-LABELING -------------------------
mydict <- c(
  "lcorn_yld"  = "log(Corn Yield)",[cite: 9]
  "lsoy_yld"   = "log(Soybean Yield)",[cite: 9]
  "D0Carea_m"  = "Abnormally Dry (D0) Cropland Share",
  "D1Carea_m"  = "Moderate Drought (D1) Cropland Share",
  "D2Carea_m"  = "Severe Drought (D2) Cropland Share",
  "D3Carea_m"  = "Extreme Drought (D3) Cropland Share",
  "D4Carea_m"  = "Exceptional Drought (D4) Cropland Share",
  "farm_dep_1" = "Farm Dependent Index",
  "irr_1"      = "Irrigated Cutoff Flag",
  "sw_dep_1"   = "Surface Water Dependent Flag",
  "gw_dep_1"   = "Groundwater Dependent Flag"
)

# --- 2. BASELINE: EXPOSURE PER CENT PERCENTAGE CROPLAND SHAPES ----------------
# Standard Panel Fixed Effects (County + Year dimensions)
reg_baseline_fe <- feols(
  c(corn_yield, soy_yield) ~ D0Carea_m + D1Carea_m + D2Carea_m + D3Carea_m + D4Carea_m | FIPS + year,[cite: 9]
  data = data, 
  vcov = vcov_conley(lat = "lat", lon = "lon", cutoff = 1380),[cite: 9]
  ssc  = ssc(fixef.K = "none", cluster.adj = FALSE, adj = TRUE)[cite: 9]
)

# Quadratic Time-Trend Specification Alternative
reg_baseline_trend <- feols(
  c(corn_yield, soy_yield) ~ D0Carea_m + D1Carea_m + D2Carea_m + D3Carea_m + D4Carea_m + trend + trend2 | FIPS,[cite: 9]
  data = data, 
  vcov = vcov_conley(lat = "lat", lon = "lon", cutoff = 1380),[cite: 9]
  ssc  = ssc(fixef.K = "none", cluster.adj = FALSE, adj = TRUE)[cite: 9]
)

# Export LaTeX formatting for baseline evaluations
etable(
  reg_baseline_fe, 
  title    = "Econometric Impacts of Drought Intensities on Crop Yields",[cite: 9]
  dict     = mydict,[cite: 9]
  tex      = TRUE,[cite: 9]
  digits   = "r5",[cite: 9]
  style.df = style.df(depvar.title = "")[cite: 9]
)

# --- 3. STRATIFIED MODEL EXTRAPOLATION: AGRICULTURAL DEPENDENCE -------------
reg_farm_interact <- feols(
  c(corn_yield, soy_yield) ~ D0Carea_m*farm_dep_1 + D1Carea_m*farm_dep_1 + D2Carea_m*farm_dep_1 + 
                             D3Carea_m*farm_dep_1 + D4Carea_m*farm_dep_1 | FIPS + year,[cite: 9]
  data = data, 
  vcov = vcov_conley(lat = "lat", lon = "lon", cutoff = 1380),[cite: 9]
  ssc  = ssc(fixef.K = "none", cluster.adj = FALSE, adj = TRUE)[cite: 9]
)

etable(reg_farm_interact, title = "Drought Heterogeneity: Agricultural Dependence", dict = mydict, tex = TRUE, digits = "r5")

# --- 4. STRATIFIED MODEL EXTRAPOLATION: IRRIGATION CAPABILITY ----------------
# Remove counties missing valid historical irrigation data profiles
data_irr_sub <- data %>% filter(!is.na(irr_1))[cite: 9]

reg_irr_interact <- feols(
  c(corn_yield, soy_yield) ~ D0Carea_m*irr_1 + D1Carea_m*irr_1 + D2Carea_m*irr_1 + 
                             D3Carea_m*irr_1 + D4Carea_m*irr_1 | FIPS + year,[cite: 9]
  data = data_irr_sub, 
  vcov = vcov_conley(lat = "lat", lon = "lon", cutoff = 1380),[cite: 9]
  ssc  = ssc(fixef.K = "none", cluster.adj = FALSE, adj = TRUE)[cite: 9]
)

etable(reg_irr_interact, title = "Drought Heterogeneity: Irrigation Infrastructure", dict = mydict, tex = TRUE, digits = "r5")

# --- 5. STRATIFIED MODEL EXTRAPOLATION: EXTRACTION WATER SOURCE --------------
# Surface Water Interactions
reg_sw_interact <- feols(
  c(corn_yield, soy_yield) ~ D0Carea_m*sw_dep_1 + D1Carea_m*sw_dep_1 + D2Carea_m*sw_dep_1 + 
                             D3Carea_m*sw_dep_1 + D4Carea_m*sw_dep_1 | FIPS + year,[cite: 9]
  data = data, 
  vcov = vcov_conley(lat = "lat", lon = "lon", cutoff = 1380),[cite: 9]
  ssc  = ssc(fixef.K = "none", cluster.adj = FALSE, adj = TRUE)[cite: 9]
)

# Compound Triple Interaction Slices (Surface vs Groundwater)
reg_triple_sw <- feols(
  c(corn_yield, soy_yield) ~ D0Carea_m + D1Carea_m + D2Carea_m + D3Carea_m + D4Carea_m + 
                             D0Carea_m:irr_1:sw_dep_1 + D1Carea_m:irr_1:sw_dep_1 + D2Carea_m:irr_1:sw_dep_1 + 
                             D3Carea_m:irr_1:sw_dep_1 + D4Carea_m:irr_1:sw_dep_1 | FIPS + year,[cite: 9]
  data = data, 
  vcov = vcov_conley(lat = "lat", lon = "lon", cutoff = 1380),[cite: 9]
  ssc  = ssc(fixef.K = "none", cluster.adj = FALSE, adj = TRUE)[cite: 9]
)

reg_triple_gw <- feols(
  c(corn_yield, soy_yield) ~ D0Carea_m + D1Carea_m + D2Carea_m + D3Carea_m + D4Carea_m + 
                             D0Carea_m:irr_1:gw_dep_1 + D1Carea_m:irr_1:gw_dep_1 + D2Carea_m:irr_1:gw_dep_1 + 
                             D3Carea_m:irr_1:gw_dep_1 + D4Carea_m:irr_1:gw_dep_1 | FIPS + year,[cite: 9]
  data = data, 
  vcov = vcov_conley(lat = "lat", lon = "lon", cutoff = 1380),[cite: 9]
  ssc  = ssc(fixef.K = "none", cluster.adj = FALSE, adj = TRUE)[cite: 9]
)

message("All fixed-effect regressions and standard error lag windows evaluated.")