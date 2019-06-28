library(tidyverse)

main_data <- read.csv("C:\\Users\\Administrator\\Documents\\personal website\\WDI data bulk\\raw files\\WDI_csv\\WDIData.csv",
                      stringsAsFactors = FALSE)

sources <- read.csv("C:\\Users\\Administrator\\Documents\\personal website\\WDI data bulk\\raw files\\WDI_csv\\WDICountry-Series.csv",
                    stringsAsFactors = FALSE)

details <-  read.csv("C:\\Users\\Administrator\\Documents\\personal website\\WDI data bulk\\raw files\\WDI_csv\\WDISeries.csv",
                     stringsAsFactors = FALSE)

countries <- read.csv("C:\\Users\\Administrator\\Documents\\personal website\\WDI data bulk\\raw files\\WDI_csv\\WDICountry.csv",
                      stringsAsFactors = FALSE)

#### find formats ####

indicator_formats <- main_data %>% 
  group_by(Indicator.Name) %>% 
  summarise(avg_value = mean(X2016, na.rm = TRUE)) %>% 
  mutate(digit_count = nchar(trunc(abs(avg_value))),
         order_transform_number = ifelse(digit_count >= 10, 1/1000000000,
                                         ifelse(digit_count >= 7, 1/1000000,
                                                1)),
         order_transform_label = ifelse(digit_count >= 10, 'Billion',
                                        ifelse(digit_count >= 7, 'Million',
                                               '')),
         parens = str_extract(Indicator.Name, pattern = '\\(.+\\)$'),
         format = ifelse(grepl(pattern = '%', x = parens), '%',
                         ifelse(grepl(pattern = '\\$', x = parens), '$', NA))) %>% 
  dplyr::select(Indicator.Name, format, order_transform_number, order_transform_label)

#### clean details ####

indicators <- details %>% 
  select(`ï..Series.Code`, Topic, Indicator.Name, Source) %>% 
  rename(Series.Code = `ï..Series.Code`) %>% 
  distinct()
  
topics_indexed <- indicators %>% 
  select(Topic) %>% 
  distinct() %>% 
  mutate(id = row_number()) %>% 
  select(id, Topic)

indicator_sources_indexed <- indicators %>% 
  select(Source) %>% 
  distinct() %>% 
  mutate(id = row_number()) %>% 
  select(id, Source)

indicators_indexed <- indicators %>% 
  merge(topics_indexed) %>% 
  rename(topic_id = id) %>% 
  merge(indicator_sources_indexed) %>% 
  rename(indicator_source_id = id) %>% 
  mutate(id = row_number()) %>% 
  select(id, Series.Code, Indicator.Name, topic_id, indicator_source_id)

#### clean countries ####

country_table <- countries %>% 
  rename(CountryCode = `ï..Country.Code`, ISO_code = X2.alpha.code, UN_code = WB.2.code) %>% 
  mutate(id = row_number()) %>% 
  select(id, CountryCode, Short.Name, Long.Name, ISO_code, UN_code, Region, Currency.Unit)

#### clean sources / notes ####

country_sources <- sources %>% 
  rename(CountryCode = `ï..CountryCode`) %>% 
  select(DESCRIPTION) %>% 
  distinct() %>% 
  mutate(id = row_number()) %>% 
  rename(country_source = DESCRIPTION) %>% 
  select(id, country_source)
  
#### create country indicator source translation table ####

country_source_translation <- sources %>% 
  rename(CountryCode = `ï..CountryCode`) %>% 
  merge(country_table) %>% 
  rename(country_id = id) %>% 
  select(SeriesCode, DESCRIPTION, country_id) %>% 
  merge(indicators_indexed, by.x = 'SeriesCode', by.y= 'Series.Code') %>% 
  rename(indicator_id = id) %>% 
  select(DESCRIPTION, indicator_id, country_id) %>% 
  merge(country_sources) %>% 
  rename(country_source_id = id) %>% 
  select(country_source_id, indicator_id, country_id)

#### create main data table ####

yearly_indicator_data <- main_data %>% 
  select(2:63, -Indicator.Name) %>% 
  merge(country_table, by.x = 'Country.Code', by.y = 'CountryCode') %>% 
  select(1:62) %>% 
  rename(country_id = id) %>% 
  merge(indicators_indexed, by.x = 'Indicator.Code', by.y = 'Series.Code') %>% 
  rename(indicator_id = id) %>% 
  select(country_id, indicator_id, 3:61)

melted_yearly_data <- yearly_indicator_data %>% 
  gather(key = 'year', value = 'indicator_value', -country_id, - indicator_id) %>% 
  filter(!is.na(indicator_value)) %>% 
  mutate(year = substr(year, 2, 5))

#### write to DB ####

dbWriteTable(conn =  con,value =  country_table, name = 'WDI_Countries')
dbWriteTable(conn =  con,value =  indicators_indexed, name = 'WDI_Indicators')
dbWriteTable(conn =  con,value =  country_source_translation, name = 'WDI_Country_Source_Translation')
dbWriteTable(conn =  con,value =  topics_indexed, name = 'WDI_Topics')
dbWriteTable(conn =  con,value =  country_sources, name = 'WDI_Country_Sources')
dbWriteTable(conn =  con,value =  melted_yearly_data, name = 'WDI_Yearly_Values')




