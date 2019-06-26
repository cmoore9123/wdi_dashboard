setwd("~/WBI")

raw_files <- list.files(path = 'raw data/', pattern = '^API') 

for (i in 1:length(raw_files)) {
  

orig_file <- read.csv(paste0('raw data/', raw_files[i]), header = FALSE, stringsAsFactors = FALSE)
processed_file <- orig_file[3:nrow(orig_file), c(-4, -64, -63)]
colnames(processed_file) <- processed_file[1,]
processed_file <- processed_file[-1,]
write.csv(processed_file, paste0('cleaned datasets/global links/',
                                 processed_file$`Indicator Name`[1],
                                 '.csv'),
          row.names = FALSE, na = '')
}

