# utils.R
# Equivalent to src/utils.py
# Loads and pre-aggregates climate data so it's ready for the app.
# In Python this was done with pandas; here we use dplyr.

library(dplyr)
library(readr)

raw_path <- file.path("data", "raw", "GlobalLandTemperaturesByCountry.csv")

# --- Load raw data ---
df_raw <- readr::read_csv(raw_path, show_col_types = FALSE)

# --- Add year and month columns ---
df_raw <- df_raw |>
  mutate(
    dt     = as.Date(dt),
    year   = as.integer(format(dt, "%Y")),
    month  = as.integer(format(dt, "%m"))
  ) |>
  # Filter to post-1860 
  filter(year >= 1860) |>
  rename(
    Country     = Country,
    AvgTemp     = AverageTemperature,
    AvgUncertain = AverageTemperatureUncertainty
  )

# --- Season helper ---
get_season <- function(month) {
  dplyr::case_when(
    month %in% c(12, 1, 2) ~ "Winter",
    month %in% c(3, 4, 5)  ~ "Spring",
    month %in% c(6, 7, 8)  ~ "Summer",
    TRUE                    ~ "Fall"
  )
}

df_raw <- df_raw |>
  mutate(season = get_season(month))

# --- Pre-aggregate: yearly ---
# Equivalent to df_yearly in utils.py
df_yearly <- df_raw |>
  group_by(year, Country) |>
  summarise(
    avg_temp        = mean(AvgTemp,      na.rm = TRUE),
    avg_uncertainty = mean(AvgUncertain, na.rm = TRUE),
    data_count      = sum(!is.na(AvgTemp)),
    .groups = "drop"
  ) |>
  mutate(
    temp_lower = avg_temp - avg_uncertainty,
    temp_upper = avg_temp + avg_uncertainty
  )

# --- Pre-aggregate: seasonal ---
# Equivalent to df_seasonal in utils.py
df_seasonal <- df_raw |>
  group_by(year, Country, season) |>
  summarise(
    AverageTemperature = mean(AvgTemp, na.rm = TRUE),
    .groups = "drop"
  )

# --- Pre-aggregate: monthly ---
# Equivalent to df_monthly in utils.py
df_monthly <- df_raw |>
  group_by(year, Country, month) |>
  summarise(
    AvgTemp = mean(AvgTemp, na.rm = TRUE),
    .groups = "drop"
  )

# --- UI-level constants ---
country_choices <- sort(unique(df_yearly$Country))
min_year        <- min(df_yearly$year)
max_year        <- max(df_yearly$year)