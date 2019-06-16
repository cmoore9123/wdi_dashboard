library(tidyverse)
library(shiny)
library(shinydashboard)
library(leaflet)
library(sf)
library(spData)
library(lubridate)

shinyServer(function(input, output, session) {
  
  sp_world <- spData::world
  sp_world[match('France', sp_world$name_long), 1] <- 'FR'
  sp_world[match('Norway', sp_world$name_long), 1] <- 'NO'
  sp_world[match('Somaliland', sp_world$name_long), 1] <- 'SO'
  sp_world <- select(sp_world, iso_a2)
  
  wdi_data <- read_rds("world_geo_data.rds") %>% 
    mutate(Indicator.Name = as.character(Indicator.Name),
           country = as.character(country),
           ISO = as.character(ISO))
  
  geo_data <- wdi_data %>% 
    merge(sp_world, by.x = 'ISO', by.y = 'iso_a2') %>% 
    st_as_sf()
  
  metric_choices <- wdi_data %>% 
    select(Indicator.Name) %>% 
    distinct()
  
  updateSelectInput(session = session,
                    inputId = 'indicator_choices',
                    choices = metric_choices$Indicator.Name,
                    selected = 0)
  
  leaflet_output <- reactive({
    
    geo_filtered <- geo_data %>% 
      filter(year == floor_date(input$date_selection, unit = 'year'),
             Indicator.Name == input$indicator_choices) %>% 
      mutate(standard_dev = abs(mean(value, na.rm = TRUE)-value)/sd(value, na.rm =TRUE)) %>% 
      filter(standard_dev < as.numeric(input$sd_limit))
    
    pal <- colorNumeric(palette = viridis::viridis(n = 30),
                        domain = geo_filtered$value,
                        na.color = 'white')
    
    leaflet_output <- leaflet(geo_filtered) %>% 
      addTiles() %>% 
      addPolygons(color = ~pal(value),
                  stroke = FALSE,
                  fillOpacity = 0.5,
                  highlightOptions = highlightOptions(fillOpacity = 0.7),
                  popup = ~paste0(country, '<br>', value)) %>% 
      addLegend(position = 'topright',
                pal = pal,
                value = ~value,
                na.label = 'NA',
                title = '')
  })
  
  output$world_map <- renderLeaflet({leaflet_output()})
  
})