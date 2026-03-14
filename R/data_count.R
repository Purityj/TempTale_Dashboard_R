# data_count.R
# Equivalent to src/data_count.py
# Returns two strings: the display text (temp ± uncertainty)
# and the sub-text (number of observations).

data_count_prep <- function(df, year) {
  # Filter the yearly data to the requested year
  year_df <- df[df$year == year, ]
  
  if (nrow(year_df) > 0) {
    temp         <- year_df$avg_temp[1]
    uncertainty  <- year_df$avg_uncertainty[1]
    count        <- year_df$data_count[1]
    display_text <- sprintf("%.1f \u00B1 %.1f \u00B0C", temp, uncertainty)  # ± and °
    sub_text     <- paste("Based on", count, "observations")
  } else {
    display_text <- "No Data"
    sub_text     <- paste("No records for", year)
  }
  
  list(display_text = display_text, sub_text = sub_text)
}