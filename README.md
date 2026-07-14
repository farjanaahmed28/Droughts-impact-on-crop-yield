# Modeling the Econometric Impacts of Drought on U.S. Crop Yields

This repository contains the R programming scripts for an econometric analysis evaluating the impact of drought intensity on county-level corn and soybean yields across the United States from 1990 to 2019. 

The empirical framework utilizes spatial data processing to map localized climate indices to agricultural boundaries, estimating panel regressions that account for heterogeneity in agricultural dependence, irrigation infrastructure, and irrigation water sources. 

---

## Data & Sample Selection
* **Study Area:** The sample includes all U.S. counties recording nonzero corn or soybean yields at least once during the 1990–2019 period. 
* **Sample Size:** The dataset encompasses **2,422 individual counties** with corn production data and **2,036 counties** with soybean data, with a significant overlap of **1,962 counties** producing both crops.
* **Panel Composition:** Utilizing 30 years of data, the final analysis uses an unbalanced panel with all missing observations dropped, resulting in **54,973 unique observations for corn** and a corresponding set for soybeans.

---

## Spatial & Climate Data Integration

### 1. Variables and Metrics
* **Crop Yield Data:** Annual county-level corn and soybean production and harvested acreage sourced from the **USDA National Agricultural Statistics Service (USDA-NASS)**. Yield ($x_{it}$) is defined as total production divided by harvested acres.
* **Drought Metric Construction:** High-resolution 10-day **Palmer Drought Severity Index (PDSI)** data sourced from gridMET. 
* **Spatial Processing:** Using the **2008 National Land Cover Database (NLCD)** and **2008 TIGER/Line shapefiles**, PDSI values were extracted at a 10-day resolution and overlaid with cultivated cropland boundaries.
* **Drought Intensity Classification:** Following the **U.S. Drought Monitor (USDM)** standards, continuous PDSI values were binned into five discrete daily risk exposure categories (Metrics represent the annual average proportion of a county's cultivated cropland exposed to each respective category):
  * **D0 (Abnormally Dry):** $-1.0$ to $-1.9$
  * **D1 (Moderate Drought):** $-2.0$ to $-2.9$
  * **D2 (Severe Drought):** $-3.0$ to $-3.9$
  * **D3 (Extreme Drought):** $-4.0$ to $-4.9$
  * **D4 (Exceptional Drought):** $-5.0$ or less

---

## Econometric Framework

### Baseline Model
To assess the annual impact of drought on crop yields, the baseline specification estimates the following unbalanced panel regression:

$$x_{it} = \mathbf{D_{itj}} \cdot \Gamma_j + \tau_t + c_i + \upsilon_{it}$$

Where:
* $x_{it}$ is the yearly average crop yield for county $i$ in year $t$ ($t = 1990, 1991, \dots, 2019$).
* $\mathbf{D_{itj}}$ represents a vector of five variables indicating the county-wise yearly average of the proportion of cultivated cropland impacted by drought categories $D0$ through $D4$.
* $\Gamma_j$ is the coefficient vector reflecting how an incremental increase in the proportion of total cultivated cropland affected by a given drought classification impacts a county's crop yields.
* $\tau_t$ represents **year fixed effects** to capture time-specific macroeconomic or climate shocks.
* $c_i$ represents **county fixed effects** to control for time-invariant local characteristics (e.g., soil quality, baseline topography).
* $\upsilon_{it}$ represents **Conley standard errors** to account for spatial and temporal autocorrelation in the error terms.

### Heterogeneity & Interaction Analysis
To evaluate resilience and structural vulnerabilities, the framework extends the baseline model by including **interaction terms** across three socio-agricultural sub-samples:
* **Agricultural Dependence:** Classifying counties based on the **USDA Economic Research Service (ERS) Typology Codes** (farming accounting for $\ge 25\%$ of earnings or $\ge 16\%$ of employment).
* **Irrigation Infrastructure:** Classifying a county as irrigated if the maximum observed ratio of irrigated-to-total harvested area exceeded $15\%$ across USDA Census years (1997–2017).
* **Water Source Vulnerability:** Partitioning irrigated counties by primary water source using **U.S. Geological Survey (USGS)** water-use data. Counties are classified as *surface-water-dependent* if surface water withdrawals constitute $\ge 50\%$ of total irrigation withdrawals.
---

## Repository Structure

```text
├── data_processing/
│   ├── 01_Ag_depended_counties.R          # Cleans USDA-ERS typology codes for county agricultural dependence
│   ├── 02_cropland_impacted_by_drought.R  # R-native spatial extraction of gridMET NetCDFs using exact_extract()
│   ├── 03_gather_crop_yield.R             # Processes and normalizes raw county-level USDA-NASS corn and soy yields
│   ├── 04_irrigated_harvested_cropland.R  # Compiles historical maximum ratiometric irrigation flags per county
│   └── 05_irrigation_water_source.R       # Standardizes and builds USGS historical water withdrawal source matrices
│
├── econometrics/
│   ├── 06_prepare_regression_dataset.R    # Stitches processed sub-panels into a final, clean FIPS-year master dataset
│   ├── 07_conley_spatial_cutoff.R         # Computes pairwise Haversine distances across county centroids for SE lags
│   └── 08_econometric_estimations.R       # Runs high-dimensional feols panel models with Conley SE spatial adjustments
│
└── README.md

---
