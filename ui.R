library(tidyverse)
library(shiny)
library(shinydashboard)
library(leaflet)
library(sf)
library(spData)
library(lubridate)

shinyUI(function(input, output, session) {
  
  dashboardPage(
    
    dashboardHeader(disable = TRUE),
    
    dashboardSidebar(disable = TRUE),
    
    dashboardBody(
      
      column(width = 3,
             
             box(width = 12,
                 
                 selectInput(inputId = 'indicator_choices',
                             label = 'Indicator:',
                             choices = 'indicator_choices',
                             multiple = FALSE),
                 
                 sliderInput(inputId = 'date_selection',
                             label = 'Select Year',
                             min = as.Date('1960-01-01', '%Y-%m-%d'),
                             max = as.Date('2018-01-01', '%Y-%m-%d'),
                             value = as.Date('2017-01-01', '%Y-%m-%d'),
                             timeFormat = '%Y-%m-%d'),
                 
                 sliderInput(inputId = 'sd_limit',
                             label = 'Max Standard Deviations from Mean',
                             min = 0,
                             max = 15,
                             value = 15,
                             step = 0.5)
                 
                 )
             
             ),
      
      column(width = 9,
             
             box(width = 12,
                 
                leafletOutput(outputId = 'world_map', width = '100%', height = '650px')))
    )
  )
})
