# TempTales — Temperature Dashboard (R)

An interactive R Shiny dashboard for exploring historical land surface temperature 
trends across countries from 1860 to 2013. Built as an R port of the original 
Python Shiny application.

## 🌍 Live App

[View the deployed dashboard here](https://019cee39-1c1a-b4b8-6d47-442e5f3800b2.share.connect.posit.cloud) 

---

## About

TempTales lets you compare average temperatures between any two years for any 
country in the dataset. Features include:

- **World heatmap** showing temperature by country for the selected year
- **Monthly temperature comparison** chart (baseline vs target year)
- **Seasonal temperature table** with color-coded change indicators
- **Historical events** contextualizing the selected year range
- **Data export** via CSV download

Dataset: [Berkeley Earth Surface Temperature](https://www.kaggle.com/datasets/berkeleyearth/climate-change-earth-surface-temperature-data) — monthly average land temperatures by country.

---

## Installation

### Prerequisites

- R (>= 4.1.0)
- RStudio (recommended)

### 1. Clone the repository
```bash
git clone https://github.com/Purityj/TempTale_Dashboard_R.git
cd TempTale_Dashboard_R
```

### 2. Install required packages

Open RStudio, then run:
```r
source("install.R")
```

This installs all required packages: `shiny`, `bslib`, `dplyr`, `plotly`, `DT`, and `readr`.

### 3. Download the data

Download the dataset from Kaggle:
[Berkeley Earth Climate Data](https://www.kaggle.com/datasets/berkeleyearth/climate-change-earth-surface-temperature-data)

Place `GlobalLandTemperaturesByCountry.csv` in:
```
data/raw/GlobalLandTemperaturesByCountry.csv
```

---

## Running the App

In the RStudio console, run:
```r
shiny::runApp()
```

Or navigate to app.R and click on "Run App" button.

---

## Project Structure
```
TempTale_Dashboard_R/
├── app.R              # App entry point
├── ui.R               # UI layout (navbar, sidebar, cards)
├── server.R           # Server logic and reactive outputs
├── install.R          # Package installation script
├── manifest.json      # Posit Connect deployment manifest
├── R/
│   ├── utils.R        # Data loading and pre-aggregation
│   ├── data_count.R   # Helper: temperature display text
│   ├── plot.R         # Plotly chart builders
│   └── map.R          # Choropleth map builder
└── data/
    └── raw/
        └── GlobalLandTemperaturesByCountry.csv
```

---

## Author

Purity Jangaya
