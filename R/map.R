# map.R
# Equivalent to src/map.py
# Builds the Plotly choropleth world heatmap.
# Python -> FigureWidget for reactive updates;
# R -> re-render the plot reactively.

library(plotly)

build_base_map <- function(df_yearly_filtered, selected_country = NULL) {

  # Highlight selected country by giving it a thicker border
  marker_line_widths <- ifelse(
    df_yearly_filtered$Country == selected_country, 3, 0.5
  )
  marker_line_colors <- ifelse(
    df_yearly_filtered$Country == selected_country, "black", "darkgray"
  )
  
  fig <- plot_ly(
    type        = "choropleth",
    locations   = df_yearly_filtered$Country,
    locationmode = "country names",
    z           = df_yearly_filtered$avg_temp,
    colorscale  = "RdBu",
    reversescale = TRUE,           # RdBu_r equivalent
    zmin        = -20,
    zmax        = 30,
    marker = list(
      line = list(
        color = marker_line_colors,
        width = marker_line_widths
      )
    ),
    colorbar = list(
      title       = "Temp (°C)",
      orientation = "h",
      len         = 0.7,
      thickness   = 12,
      x           = 0.5,
      xanchor     = "center",
      y           = -0.08,
      yanchor     = "top"
    )
  ) |>
    layout(
      geo = list(
        showframe      = FALSE,
        showcoastlines = TRUE,
        coastlinecolor = "darkgray",
        showland       = TRUE,
        landcolor      = "#eaeaea",
        showocean      = FALSE,
        projection     = list(type = "natural earth")
      ),
      margin     = list(l = 0, r = 0, t = 0, b = 30),
      paper_bgcolor = "rgba(0,0,0,0)",
      autosize   = TRUE
    )
  
  fig
}