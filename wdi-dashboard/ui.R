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
                 
                 sliderInput(inputId = 'date_select',
                             label = 'Select Year',
                             min = as.Date('1960-01-01', '%Y-%m-%d'),
                             max = as.Date('2017-01-01', '%Y-%m-%d'),
                             value = as.Date('2017-01-01'),
                             timeFormat = '%Y-%m-%d'),
                 
                 selectInput(inputId = 'metric_selection',
                             label = 'Indicator',
                             multiple = FALSE,
                             choices = 'metric_selection'),
                 
                 sliderInput(inputId = 'sd_limit',
                             label = 'Max Standard Deviations',
                             min = 0,
                             max = 15, value = 10,
                             step = 0.5)
                 
                 )
             ),
      column(width = 9,
             
             box(width = 12,
               
               withSpinner(leafletOutput(outputId = 'world_map', width = '100%', height = '650px'))
             ))
      
      
    )
  )
  
  
})