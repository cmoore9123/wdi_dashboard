library(tidyverse)
library(lubridate)
library(leaflet)
library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(sf)
library(DT)

shinyUI(function(input, output, session) {
  
  dashboardPage(
    
    dashboardHeader(disable = TRUE),
    
    dashboardSidebar(disable = TRUE),
    
    dashboardBody(
      
      column(width = 3,
             
             box(width = 12,
                 
                 selectInput(inputId = 'topic_selection',
                             label = 'Indicator topic',
                             multiple = FALSE,
                             choices = 'topic_selection', 
                             selectize = FALSE),
                 
                 selectInput(inputId = 'metric_selection',
                             label = 'Indicator',
                             multiple = FALSE,
                             choices = 'metric_selection', 
                             selectize = FALSE),
                 
                 sliderInput(inputId = 'date_select',
                             label = 'Select Year',
                             min = 1960,
                             max = 2018,
                             value = 2017,
                             sep = ''),
                 
                 sliderInput(inputId = 'sd_limit',
                             label = 'Max Standard Deviations',
                             min = 0,
                             max = 15, value = 10,
                             step = 0.5)
                 
             )
      ),
      column(width = 9,
             
             box(width = 12,
                 
                 withSpinner(leafletOutput(outputId = 'world_map', height = '500px'))
             ))
      
      
    )
  )
  
  
})