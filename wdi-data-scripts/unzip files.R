setwd("~/WBI")

zipped_files <- list.files("C:\\Users\\C6728215\\Documents\\WBI\\zipped data\\")

for (i in 1:length(zipped_files)) {

unzip(zipfile = paste0("C:\\Users\\C6728215\\Documents\\WBI\\zipped data\\", zipped_files[i]),
      exdir = "C:\\Users\\C6728215\\Documents\\WBI\\raw data")
  
}











