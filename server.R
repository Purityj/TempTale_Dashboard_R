# server.R
# All reactive calculations and output renderers live here.
# In R Shiny: reactive() = @reactive.Calc, observe() = @reactive.Effect

library(shiny)
library(dplyr)
library(plotly)
library(DT)

server <- function(input, output, session) {
  
  # ============================================================
  # Reactive: validate year range
  # Equivalent to selected_range() in app.py
  # Returns a list: list(b, t, err)
  # ============================================================
  
  # Populate country dropdown once app loads
  # This avoids ui.R needing country_choices at parse time
  observe({
    updateSelectInput(session, "country",
                      choices  = country_choices,
                      selected = "Canada")
  }) |> bindEvent(session$clientData$url_hostname, once = TRUE)
  
  selected_range <- reactive({
    b <- input$baseline_year
    t <- input$target_year
    
    if (is.null(b) || is.null(t) || is.na(b) || is.na(t)) {
      return(list(b = NULL, t = NULL, err = "Enter both years."))
    }
    
    b <- as.integer(b)
    t <- as.integer(t)
    
    if (b < min_year || b > max_year) {
      return(list(b = NULL, t = NULL,
                  err = paste("Reference year must be between", min_year, "and", max_year)))
    }
    if (t < min_year || t > max_year) {
      return(list(b = NULL, t = NULL,
                  err = paste("Target year must be between", min_year, "and", max_year)))
    }
    if (t <= b) {
      return(list(b = NULL, t = NULL,
                  err = "Target year must be greater than reference year."))
    }
    
    list(b = b, t = t, err = NULL)
  })
  
  # ============================================================
  # Reactive: filter yearly data for selected country
  # Equivalent to filtered_yearly_data()
  # ============================================================
  filtered_yearly_data <- reactive({
    df_yearly |> filter(Country == input$country)
  })
  
  # ============================================================
  # Reactive: filter yearly data for selected year range
  # Equivalent to filtered_global_data()
  # ============================================================
  filtered_global_data <- reactive({
    r <- selected_range()
    if (!is.null(r$err)) return(data.frame())
    
    filtered_yearly_data() |>
      filter(year >= r$b & year <= r$t)
  })
  
  # ============================================================
  # Reactive: monthly comparison data (long format for chart)
  # ============================================================
  monthly_comparison_data <- reactive({
    r <- selected_range()
    if (!is.null(r$err)) return(data.frame())
    
    month_labels <- c("Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec")
    
    df <- df_monthly |>
      filter(Country == input$country, year %in% c(r$b, r$t))
    
    if (nrow(df) == 0) return(data.frame())
    
    base_df <- df |> filter(year == r$b) |>
      select(month, AvgTemp) |>
      rename(!!paste0(r$b, "_avg") := AvgTemp)
    
    target_df <- df |> filter(year == r$t) |>
      select(month, AvgTemp) |>
      rename(!!paste0(r$t, "_avg") := AvgTemp)
    
    merged <- base_df |>
      inner_join(target_df, by = "month") |>
      mutate(
        Change = round(.data[[paste0(r$t, "_avg")]] - .data[[paste0(r$b, "_avg")]], 2),
        Month  = month_labels[month]
      ) |>
      mutate(across(where(is.numeric), ~ round(.x, 2))) |>
      select(Month, ends_with("_avg"), Change)
    
    merged
  })
  
  # ============================================================
  # Reactive: monthly comparison wide format (for data table)
  # ============================================================
  monthly_comparison_wide <- reactive({
    data <- monthly_comparison_data()
    if (nrow(data) == 0) return(data.frame())
    
    r <- selected_range()
    if (!is.null(r$err)) return(data.frame())
    
    base_col   <- paste0(r$b, "_avg")
    target_col <- paste0(r$t, "_avg")
    month_labels <- c("Jan","Feb","Mar","Apr","May","Jun",
                      "Jul","Aug","Sep","Oct","Nov","Dec")
    
    # Build each row as a named list then combine — avoids matrix transpose issues
    baseline_row <- setNames(as.list(round(data[[base_col]],   2)), month_labels)
    target_row   <- setNames(as.list(round(data[[target_col]], 2)), month_labels)
    change_row   <- setNames(as.list(round(data$Change,        2)), month_labels)
    
    df_wide <- rbind(
      cbind(data.frame(Metric = "Baseline (°C)", stringsAsFactors = FALSE), as.data.frame(baseline_row)),
      cbind(data.frame(Metric = "Target (°C)",   stringsAsFactors = FALSE), as.data.frame(target_row)),
      cbind(data.frame(Metric = "Change (°C)",   stringsAsFactors = FALSE), as.data.frame(change_row))
    )
    
    df_wide
  })
  
  # ============================================================
  # UI: year validation message
  # Equivalent to year_validation_ui output
  # ============================================================
  output$year_validation_ui <- renderUI({
    r <- selected_range()
    if (!is.null(r$err)) {
      span(r$err, style = "color: red;")
    } else {
      span("Year range is valid.", style = "color: green;")
    }
  })
  
  # ============================================================
  # UI: data count (avg temp + uncertainty + observations)
  # Equivalent to data_count_ui output
  # ============================================================
  output$data_count_ui <- renderUI({
    data <- filtered_global_data()
    r    <- selected_range()
    if (!is.null(r$err)) return(NULL)
    
    # Use the helper from data_count.R
    b_result <- data_count_prep(data, r$b)
    t_result <- data_count_prep(data, r$t)
    
    tagList(
      h6(paste("Year", r$b)),
      h5(b_result$display_text, style = "color: #0d6efd;"),
      p(b_result$sub_text,      class = "text-muted small mb-0"),
      h6(paste("Year", r$t)),
      h5(t_result$display_text, style = "color: #0d6efd;"),
      p(t_result$sub_text,      class = "text-muted small mb-0")
    )
  })
  
  # ============================================================
  # UI: historical events
  # Equivalent to event_ui output
  # ============================================================
  output$event_ui <- renderUI({
    r <- selected_range()
    if (!is.null(r$err)) return(NULL)
    
    events <- list(
      c(1860, 1900, "Post-Industrial Revolution"),
      c(1914, 1918, "World War I"),
      c(1939, 1945, "World War II"),
      c(1987, 1989, "Montreal Protocol Signed"),
      c(1997, 2012, "Kyoto Protocol Era")
    )
    
    # Find events that overlap with the selected year range
    matching <- Filter(function(ev) {
      ev_s <- as.integer(ev[1])
      ev_e <- as.integer(ev[2])
      (r$b <= ev_s && ev_s <= r$t) || (r$b <= ev_e && ev_e <= r$t)
    }, events)
    
    if (length(matching) == 0) {
      return(p("No major recorded events in selected range.",
               class = "text-muted small"))
    }
    
    # Build list items
    items <- lapply(matching, function(ev) {
      tags$li(paste0(ev[1], "-", ev[2], ": ", ev[3]),
              class = "text-muted small")
    })
    
    tags$ul(items)
  })
  
  # ============================================================
  # UI: seasonal temperature table
  # Equivalent to seasonal_temp_ui output
  # ============================================================
  output$seasonal_temp_ui <- DT::renderDT({
    r <- selected_range()
    
    if (!is.null(r$err)) {
      return(DT::datatable(data.frame(Message = "Invalid year selection")))
    }
    
    country  <- input$country
    seasons  <- c("Spring", "Summer", "Fall", "Winter")
    
    df_b <- df_seasonal |> filter(Country == country, year == r$b)
    df_t <- df_seasonal |> filter(Country == country, year == r$t)
    
    # Build a 4-row table: one row per season
    rows <- lapply(seasons, function(s) {
      val_b <- df_b |> filter(season == s) |> pull(AverageTemperature)
      val_t <- df_t |> filter(season == s) |> pull(AverageTemperature)
      
      temp_b <- if (length(val_b) > 0) round(val_b[1], 1) else NA
      temp_t <- if (length(val_t) > 0) round(val_t[1], 1) else NA
      change <- if (!is.na(temp_b) && !is.na(temp_t)) round(temp_t - temp_b, 1) else NA
      
      data.frame(
        Season = s,
        Baseline = if (!is.na(temp_b)) temp_b else "N/A",
        Target   = if (!is.na(temp_t)) temp_t else "N/A",
        Change   = change,
        stringsAsFactors = FALSE
      )
    })
    
    df_table <- do.call(rbind, rows)
    names(df_table)[2:3] <- c(as.character(r$b), as.character(r$t))
    
    # Color-code Change column using DT's formatStyle
    DT::datatable(
      df_table,
      selection = "none",
      options   = list(dom = "t", ordering = FALSE)  # hide search/pagination
    ) |>
      DT::formatStyle(
        "Change",
        color           = DT::styleInterval(c(0), c("#2980b9", "#c0392b")),
        backgroundColor = DT::styleInterval(
          c(0),
          c("rgba(52,152,219,0.15)", "rgba(231,76,60,0.15)")
        )
      )
  })
  
  # ============================================================
  # UI: navbar title (value box equivalent)
  # Equivalent to title_placeholder output
  # ============================================================
  output$title_placeholder <- renderUI({
    r <- selected_range()
    if (!is.null(r$err)) {
      return(span("TempTales", class = "fw-bold"))
    }
    
    span(
      paste0("TempTales — ", input$country, ": ",
             r$b, " vs ", r$t, " (Temperature Comparison)"),
      class = "fw-bold"
    )
  })
  
  # ============================================================
  # Output: temperature line chart (monthly dual-line)
  # Equivalent to temp_plot output
  # ============================================================
  output$temp_plot <- renderPlotly({
    data <- monthly_comparison_data()
    r    <- selected_range()
    
    if (!is.null(r$err) || nrow(data) == 0) {
      return(build_temp_chart(data.frame(), 0, 0, "", height = 280))
    }
    
    build_temp_chart(data, r$b, r$t, input$country, height = 280)
  })
  
  # ============================================================
  # Output: world choropleth map
  # Equivalent to map_plot + update_map_data in app.py
  # In R, we just re-render the full Plotly chart reactively
  # (no need for FigureWidget mutation).
  # ============================================================
  output$map_plot <- renderPlotly({
    r <- selected_range()
    
    # Default to max year if range is invalid
    target_year <- if (!is.null(r$err)) max_year else r$t
    
    df_year_filtered <- df_yearly |> filter(year == target_year)
    
    build_base_map(df_year_filtered, selected_country = input$country)
  })
  
  # ============================================================
  # Output: data table (monthly comparison, wide format)
  # Equivalent to data_table output
  # ============================================================
  output$data_table <- DT::renderDT({
    data <- monthly_comparison_wide()
    
    if (nrow(data) == 0) {
      return(DT::datatable(data.frame()))
    }
    
    # Color-code the Change row (row index 3)
    # DT uses 1-based row indices in JS, so row 3 = Change row
    dt <- DT::datatable(
      data,
      selection = "none",
      options   = list(dom = "t", ordering = FALSE, scrollX = TRUE)
    )
    
    # Apply color to each month column in the Change row
    for (col in names(data)[-1]) {   # skip "Metric" column
      dt <- dt |>
        DT::formatStyle(
          col,
          rows            = 3,  # Change row
          color           = DT::styleInterval(c(0), c("#2980b9", "#c0392b")),
          backgroundColor = DT::styleInterval(
            c(0),
            c("rgba(52,152,219,0.15)", "rgba(231,76,60,0.15)")
          )
        )
    }
    
    dt
  })
  
  # ============================================================
  # Download: CSV export
  # Equivalent to download_table_csv output
  # ============================================================
  output$download_table_csv <- downloadHandler(
    filename = function() {
      r       <- selected_range()
      country <- gsub(" ", "_", input$country)
      if (!is.null(r$err)) return("temperature_data.csv")
      paste0("temperature_", country, "_", r$b, "_", r$t, ".csv")
    },
    content = function(file) {
      data <- monthly_comparison_wide()
      write.csv(data, file, row.names = FALSE)
    }
  )
  
}