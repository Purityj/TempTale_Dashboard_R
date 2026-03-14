# plot.R
# Equivalent to src/plot.py
# Builds Plotly charts

library(plotly)
library(dplyr)

# --- Monthly dual-line temperature comparison ---
# Equivalent to build_temp_chart() in plot.py
build_temp_chart <- function(data, baseline_year, target_year, country, height = 280) {
  
  month_labels <- c("Jan","Feb","Mar","Apr","May","Jun",
                    "Jul","Aug","Sep","Oct","Nov","Dec")
  
  # If no data, return an empty placeholder chart
  if (nrow(data) == 0) {
    return(plot_ly() |>
             layout(title = "No data available",
                    xaxis = list(title = "Month"),
                    yaxis = list(title = "Temperature (°C)")))
  }
  
  base_col   <- paste0(baseline_year, "_avg")
  target_col <- paste0(target_year,   "_avg")
  
  # Build the Plotly figure with two lines
  fig <- plot_ly(data, x = ~Month) |>
    # Baseline year line
    add_trace(
      y         = data[[base_col]],
      name      = as.character(baseline_year),
      type      = "scatter",
      mode      = "lines+markers",
      line      = list(color = "#2C7A7B", width = 2),
      marker    = list(size = 6),
      hovertemplate = paste0("<b>%{x}</b><br>", baseline_year, ": %{y:.2f}°C<extra></extra>")
    ) |>
    # Target year line
    add_trace(
      y         = data[[target_col]],
      name      = as.character(target_year),
      type      = "scatter",
      mode      = "lines+markers",
      line      = list(color = "#38B2AC", width = 2),
      marker    = list(size = 6),
      hovertemplate = paste0("<b>%{x}</b><br>", target_year, ": %{y:.2f}°C<extra></extra>")
    ) |>
    layout(
      title = list(
        text = paste0("Temperature Overlay Comparison<br>",
                      "<sup>Monthly average temperatures for ", country,
                      " (", baseline_year, " vs ", target_year, ")</sup>"),
        font = list(size = 14)
      ),
      xaxis  = list(title = "Month", tickvals = 1:12, ticktext = month_labels),
      yaxis  = list(title = "Temperature (°C)"),
      legend = list(orientation = "h", x = 0.5, xanchor = "center", y = -0.15),
      height = height,
      margin = list(t = 60, b = 60)
    )
  
  fig
}

# --- Yearly centered time series (for AI tab, included for completeness) ---
# Equivalent to build_yearly_plot() in plot.py
build_yearly_plot <- function(df_yearly) {
  plot_ly(df_yearly, x = ~year, y = ~AvgTemp_centered,
          color = ~Country, type = "scatter", mode = "lines+markers") |>
    layout(
      xaxis = list(title = "Year"),
      yaxis = list(title = "Centered Avg Temp (°C)"),
      height = 300
    )
}

# --- Monthly temperature diff (for AI tab) ---
# Equivalent to build_diff_plot() in plot.py
build_diff_plot <- function(df_monthly_diff) {
  month_labels <- c("Jan","Feb","Mar","Apr","May","Jun",
                    "Jul","Aug","Sep","Oct","Nov","Dec")
  plot_ly(df_monthly_diff, x = ~month, y = ~AvgTemp_diff,
          color = ~Country, type = "scatter", mode = "lines+markers") |>
    layout(
      xaxis = list(title = "Month", tickvals = 1:12, ticktext = month_labels),
      yaxis = list(title = "Monthly Avg Temp Difference (°C)"),
      height = 300
    )
}