library(tidyverse)
library(lubridate)
library(leaflet)
library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(sf)
library(DT)

shinyServer(function(input, output, session) {
  
  indicator_formats <- read_rds('format_table.rds')
  
  sp_world <- spData::world
  sp_world[match(c('France'), sp_world$name_long),1] <- 'FR'
  sp_world[match(c('Norway'), sp_world$name_long),1] <- 'NO'
  sp_world[match(c('Somaliland'), sp_world$name_long),1] <- 'SO'
  
  sp_world <- sp_world %>% select(iso_a2)
  
  geo_metrics <- read_rds('indicator_data.rds') %>% 
    merge(sp_world, by.x = 'ISO', by.y = 'iso_a2') %>% 
    st_as_sf()
  
  metric_choices <- indicator_formats %>% 
    select(Indicator.Name) %>% 
    distinct()
  
  updateSelectInput(session = session,
                    inputId = 'metric_selection',
                    choices = metric_choices$Indicator.Name,
                    selected = 0)
  
  format_type <- reactive({
    format_type <- indicator_formats %>% 
      filter(Indicator.Name == input$metric_selection)
  })
  
  leaflet_output <- reactive({
    
    geo_metrics_filtered <- geo_metrics %>% 
      filter(year == floor_date(as.Date(input$date_select), unit = 'year'),
             Indicator.Name == input$metric_selection) %>% 
      mutate(standard_dev = abs(mean(value, na.rm = TRUE)-value)/sd(value, na.rm = TRUE),
             value = value/format_type()[1,3]) %>% 
      filter(standard_dev < as.numeric(input$sd_limit))
    
    pal <-  colorNumeric(palette =  viridis::viridis(n = 30),
                         domain = geo_metrics_filtered$value,
                         na.color = 'white')
    
    leaflet_output <- leaflet(geo_metrics_filtered) %>% 
      addTiles() %>% 
      addPolygons(color = ~pal(value),
                  fillOpacity = 0.5,
                  stroke = FALSE,
                  highlightOptions = highlightOptions(fillOpacity = 0.7),
                  popup = ~(paste0(COUNTRY, '<br>',
                                  format_type()[1, 4],
                                  formatC(value,
                                          digits = 2,
                                          format = 'f',
                                          big.mark = ','),
                                  format_type()[1,5]))) %>% 
      addLegend(position = 'topright',
                pal = pal,
                values = ~value,
                na.label = 'NA',
                title = format_type()[1, 6],
                labFormat = labelFormat(prefix = format_type()[1, 4],
                                        suffix = format_type()[1, 5],
                                        digits = 2,
                                        big.mark = ','))
    
  })
  
  output$world_map <- renderLeaflet({leaflet_output()})
  
  
  
})