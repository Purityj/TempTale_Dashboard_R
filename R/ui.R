# ui.R
# Equivalent to src/ui.py
# Defines the app layout using bslib (Bootstrap-based Shiny UI).

library(shiny)
library(bslib)
library(DT)
library(plotly)

# --- Footer metadata (update on release) ---
FOOTER_LAST_UPDATED <- "2026-03-14"
REPO_URL            <- "https://github.com/Purityj/TempTale_Dashboard_R"
AUTHOR        <- c( "Purity Jangaya")

# ==========================================
# Sidebar inputs
# ==========================================
app_sidebar <- sidebar(
  selectInput(
    inputId  = "country",
    label    = "Select Country",
    choices  = NULL,  # will be populated by server on startup
    selected = NULL
  ),
  numericInput(
    inputId = "baseline_year",
    label   = "Select Reference Year:",
    value   = 1950,
    min     = 1860,
    max     = 2012,
    step    = 1
  ),
  numericInput(
    inputId = "target_year",
    label   = "Select Target Year:",
    value   = 2000,
    min     = 1860,
    max     = 2012,
    step    = 1
  ),
  # Year validation message (updated reactively in server.R)
  uiOutput("year_validation_ui"),
  title = "Filters",
  open  = FALSE   # starts collapsed, same as open="closed" in Python
)

# ==========================================
# Left column cards
# ==========================================
data_count_card <- card(
  card_header("Yearly Average Temperature"),
  uiOutput("data_count_ui")
)

event_card <- card(
  card_header("Historical Event"),
  uiOutput("event_ui"),
  class = "bg-light"
)

seasonal_temp_card <- card(
  card_header("Seasonal Temperature"),
  DTOutput("seasonal_temp_ui")   # DT replaces render.DataGrid
)

left_column <- div(
  data_count_card,
  event_card,
  seasonal_temp_card
)

# ==========================================
# Right area cards
# ==========================================
map_plot_card <- card(
  card_header("World Heatmap"),
  plotlyOutput("map_plot", height = "100%"),
  full_screen = TRUE,
  style = "height: 100%;"
)

temp_plot_card <- card(
  card_header("Temperature Over Time"),
  plotlyOutput("temp_plot", height = "100%"),
  full_screen = TRUE,
  style = "height: 100%;"
)

table_card <- card(
  card_header(
    div(
      "Data Table",
      downloadButton("download_table_csv", "Export CSV",
                     class = "btn-sm float-end")
    )
  ),
  DTOutput("data_table")
)

# Top row: map + line chart side by side
charts_row <- layout_columns(
  map_plot_card,
  temp_plot_card,
  col_widths = c(6, 6)
)

right_area <- div(
  div(charts_row, style = "flex: 7; min-height: 0;"),
  div(table_card,  style = "flex: 3; min-height: 0;"),
  style = "display: flex; flex-direction: column; min-height: 55vh;"
)

# ==========================================
# Main dashboard content
# ==========================================
main_content <- layout_columns(
  left_column,
  right_area,
  col_widths = c(3, 9)
)

# ==========================================
# Footer
# ==========================================
author_text <- paste(AUTHOR, collapse = " · ")

app_footer <- tags$footer(
  div(
    span(author_text),
    span(" · ", class = "text-muted"),
    tags$a("Repository", href = REPO_URL, target = "_blank"),
    span(" · ", class = "text-muted"),
    span(paste("Last updated:", FOOTER_LAST_UPDATED), class = "text-muted small"),
    class = "d-flex align-items-center justify-content-center gap-2 py-2 px-3"
  ),
  class = "border-top bg-light",
  style = "position: fixed; bottom: 0; left: 0; right: 0; z-index: 1000; font-size: 0.875rem;"
)

# ==========================================
# Final app UI (navbar with tabs)
# ==========================================
app_ui <- page_navbar(
  title   = uiOutput("title_placeholder"),
  id      = "main_nav",
  sidebar = app_sidebar,
  footer  = app_footer,
  fillable = TRUE,
  # padding: top right bottom left (extra bottom for fixed footer)
  padding = c(10, 10, 60, 10),
  
  # Dashboard tab
  nav_panel("Dashboard", main_content, value = "dashboard"),
  
  # AI tab placeholder (to be added later)
  nav_panel("AI Assistant", p("Coming soon"), value = "ai_assistant")
)