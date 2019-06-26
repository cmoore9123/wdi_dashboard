setwd("~/WBI")

clean_files <- list.files(path = 'cleaned datasets/global links')

combined_files <- data.frame()

for (i in 1:length(clean_files)) {
  
  orig_file <- read.csv(paste0('cleaned datasets/global links/', clean_files[i]), stringsAsFactors = FALSE)
  combined_files <- rbind(combined_files, orig_file)
}

code_translation <-  read.csv("C:\\Users\\C6728215\\Documents\\WBI\\country_codes.csv",
                              stringsAsFactors = FALSE)

combined_geo <- combined_files %>% 
  merge(code_translation, by.x = 'Country.Code', by.y = 'UN', all.x = TRUE) %>% 
  filter(!is.na(ISO)) %>% 
  select(-Country.Name, -Country.Code) %>% 
  gather(key = 'year', value = 'value', -COUNTRY, -ISO , -Indicator.Name) %>% 
  mutate(year = floor_date(as.Date(substr(year, 2, 5), '%Y'), unit = 'years'))

indicator_names <- combined_geo %>% 
  select(Indicator.Name) %>% 
  distinct() %>% 
  mutate(ID = seq.int(nrow(.)))

combined_geo <- combined_geo %>% 
  merge(indicator_names) %>% 
  select(-Indicator.Name)



write_rds(combined_geo, 'cleaned and combined data/indicator_data.rds')
write_rds(indicator_names, 'cleaned and combined data/indicator_name_lookup.rds')

formats <- read.csv("C:\\Users\\C6728215\\Documents\\WBI\\indicator_formats1.csv", stringsAsFactors = FALSE)
write_rds(formats, 'cleaned and combined data/format_table.rds')
