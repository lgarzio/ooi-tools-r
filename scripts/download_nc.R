# author: Lori Garzio
# Download data in NetCDF file format (asynchronous request) via the OOI API. The data will be processed and served via THREDDs.
# 2018-06-08
# refs: https://www.r-bloggers.com/accessing-apis-from-r-and-a-little-r-programming/

# Load required packages
library(httr)
library(jsonlite)

# ----------------------------------------Functions----------------------------------------

# Return a data request url
DataRequestUrl <- function(subsite, node, sensor, method, stream, beginDT, endDT) {
  base <- 'https://ooinet.oceanobservatories.org/api/m2m/12576/sensor/inv'
  url <- paste(base,subsite,node,sensor,method,stream,sep='/')
  
  if (nchar(beginDT) == 0 & nchar(endDT) == 0) {
    endpoint <- paste(url,'?include_provenance=true&include_annotations=true',sep='')
  } else {
    endpoint <- paste(url,'?beginDT=',beginDT,'&endDT=',endDT,'&include_provenance=true&include_annotations=true',sep='')
  } 
  
  return(endpoint)
}

SendDataRequest <- function(url, username, token) {
  response <- GET(url, authenticate(username, token))
  r_text <- fromJSON((content(response, 'text')), flatten = TRUE)
  
  if (response$status_code == 200) {
    print("Request successful!")
  } else {
    stop(
      sprintf("Request unsuccessful. status_code %s %s", response$status_code, r_text$message$status)
    )
  }
  
  data_url <- r_text$outputURL
  return(data_url)
}

# ----------------------------------------User Inputs----------------------------------------

# Specify API username and password from ooinet.oceanobservatories.org
sdir <- "/Users/lgarzio/Documents/repo/R_scripts" # location to save output
username <- "OOIAPI-D8S960UXPK4K03"
token <- "IXL48EQ2XY"

# Specify sensor/method/stream of interest. Information can be found at ooi.visualocean.net
subsite <- "GA03FLMA"
node <- "RIM01"
sensor <- "02-CTDMOG040"
method <- "recovered_inst"
stream <- "ctdmo_ghqr_instrument_recovered"

# Constrain dates for data request. Use "" to request the full time-range available in the system.
beginDT <- '2015-11-25T19:21:00.000Z'
endDT <- '2016-11-05T18:58:00.000Z'
#beginDT <- ""
#endDT <- ""

data_request_url <- DataRequestUrl(subsite, node, sensor, method, stream, beginDT, endDT)
data_request_url

# Send the data request and output the url that contains the files to .csv
data_url <- SendDataRequest(data_request_url, username, token)
data_url
write.table(data_url, file = paste(sdir, "data_url.csv", sep="/"), row.names = FALSE, col.names = FALSE)