library(tidyverse)
library(lubridate)
library(leaflet)
library(shiny)
library(shinydashboard)
library(shinycssloaders)
library(sf)
library(DT)
library(RMySQL)

con <- dbConnect(MySQL(), user='wordpressuser', password='Bitsy444', dbname='dataconductor', host='localhost')

sp_world <- spData::world
sp_world[match(c('France'), sp_world$name_long),1] <- 'FR'
sp_world[match(c('Norway'), sp_world$name_long),1] <- 'NO'
sp_world[match(c('Somaliland'), sp_world$name_long),1] <- 'SO'
sp_world <- sp_world %>% select(iso_a2)


shinyServer(function(input, output, session) {
  
  topics <- dbGetQuery(con, "SELECT * FROM dataconductor.WDI_Topics;")
  topic_choices <- topics$Topic
  
  updateSelectInput(session = session,
                    inputId = 'topic_selection',
                    choices = topic_choices,
                    selected = 0)
  
  observeEvent(input$topic_selection, {
    metric_choices <- dbGetQuery(con, paste0("SELECT `Indicator.Name` FROM dataconductor.WDI_Indicators i
                                             INNER JOIN dataconductor.WDI_Topics t ON t.id = i.topic_id
                                             WHERE t.Topic = '", input$topic_selection, "';")) 
    
    updateSelectInput(session = session,
                      inputId = 'metric_selection',
                      choices = metric_choices)
    
  })
  
  
  
  leaflet_output <- reactive({
    
    
    
    value_data <- dbGetQuery(con, paste0("SELECT 
                                         c.ISO_code,
                                         c.`Short.Name`,
                                         i.`Indicator.Name`,
                                         i.order_transform_label,
                                         i.prefix,
                                         i.suffix,
                                         v.year,
                                         (v.indicator_value * i.order_transform_number) As indicator_value
                                         FROM
                                         WDI_Yearly_Values v
                                         INNER JOIN WDI_Countries c ON c.id = v.country_id
                                         INNER JOIN WDI_Indicators i ON i.id = v.indicator_id
                                         WHERE i.`Indicator.Name` = '",input$metric_selection,"' 
                                         AND v.year = '", input$date_select, "'")) %>% 
      mutate(suffix = replace_na(suffix, ''),
             prefix = replace_na(prefix, ''))
    
    geo_metrics <- value_data %>% 
      merge(sp_world, by.x = 'ISO_code', by.y = 'iso_a2') %>% 
      st_as_sf()
    
    geo_metrics_filtered <- geo_metrics %>% 
      mutate(standard_dev = abs(mean(indicator_value, na.rm = TRUE)-indicator_value)/sd(indicator_value, na.rm = TRUE),
             indicator_value = indicator_value) %>% 
      filter(standard_dev < as.numeric(input$sd_limit))
    
    pal <-  colorNumeric(palette =  viridis::viridis(n = 30),
                         domain = geo_metrics_filtered$indicator_value,
                         na.color = 'white')
    
    leaflet_output <- leaflet(geo_metrics_filtered) %>% 
      setView(lng = 0, lat = 22, zoom = 2) %>% 
      addTiles() %>% 
      addPolygons(color = ~pal(indicator_value),
                  fillOpacity = 0.5,
                  stroke = FALSE,
                  highlightOptions = highlightOptions(fillOpacity = 0.7),
                  popup = ~(paste0(Short.Name, '<br>',
                                   prefix,
                                   formatC(indicator_value,
                                           digits = 2,
                                           format = 'f',
                                           big.mark = ','),
                                   ' ',
                                   suffix))) %>% 
      addLegend(position = 'topright',
                pal = pal,
                values = ~indicator_value,
                na.label = 'NA',
                title = paste0(value_data$prefix[1], ' ', value_data$suffix[1]),
                labFormat = labelFormat(digits = 2,
                                        big.mark = ','))
    
  })
  
  output$world_map <- renderLeaflet({leaflet_output()})
  
})
