library(shiny)
library(bslib)
library(dplyr)
library(plotly)
library(DT)
library(readr)

filter <- dplyr::filter

source("R/utils.R")
source("R/data_count.R")
source("R/plot.R")
source("R/map.R")
source("R/ui.R")
source("server.R")

shinyApp(ui = app_ui, server = server)

