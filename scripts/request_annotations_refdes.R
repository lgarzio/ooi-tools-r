# author: Lori Garzio
# Return a .csv containing annotations in uFrame for a reference designator
# 2018-06-12
# refs: https://www.r-bloggers.com/accessing-apis-from-r-and-a-little-r-programming/
# helpful resource: ooi.visualocean.net

# Load required packages
library(httr)
library(jsonlite)

# ----------------------------------------Functions----------------------------------------

AnnoRequestURL <- function(refdes, beginDT, endDT){
  # Build the annotation request url
  anno_base <- 'https://ooinet.oceanobservatories.org/api/m2m/12580/anno/find/'
  url <- paste(anno_base,"?refdes=",refdes,sep="")
  
  # If requesting full time-range, specify begin date of 2013-01-01T00:00:00 and end date of current sys time.
  # Otherwise, convert the dates given to epoch timestamps in milliseconds
  if (nchar(beginDT) == 0 & nchar(endDT) == 0) {
    now = Sys.time()
    attr(now, "tzone") <- "UTC" # convert current time to UTC
    now_ms <- as.numeric(now) * 1000 # convert time to epoch timestamp in milliseconds
    endpoint <- paste(url,'&beginDT=1356998400000&endDT=',toString(round(now_ms, digits = 0)),sep='')
  } else {
    beginDTms <- ReturnDateMS(beginDT)
    endDTms <- ReturnDateMS(endDT)
    endpoint <- paste(url,'&beginDT=',beginDTms,'&endDT=',endDTms,sep='')
  } 
  return(endpoint)
}

ReturnDateMS <- function(dt) {
  # Input a date in format '2016-11-05T18:58:00.000Z' and return as an epoch timestamp in milliseconds
  dt_time <- strsplit(dt, "T")[[1]][2]
  dt_time <- substr(dt_time, 1, nchar(dt_time)-5)
  fdt <- paste(strsplit(dt, "T")[[1]][1], dt_time, sep=" ")
  fdt <- strptime(fdt, tz="UTC", format = "%Y-%m-%d %H:%M:%S")
  fdt_ms <- as.numeric(fdt) * 1000
  return(fdt_ms)
}

SendAnnotationRequest <- function(url, username, token){
  response <- GET(endpoint, authenticate(username, token))
  r_text <- fromJSON((content(response, 'text')), flatten = TRUE)
  
  if (response$status_code == 200) {
    print("Request successful!")
  } else {
    stop(
      sprintf("Request unsuccessful. status_code %s %s", response$status_code, r_text$message$status)
    )
  }
  return(r_text)
}

# ----------------------------------------User Inputs----------------------------------------

# Specify API username and password from ooinet.oceanobservatories.org
sdir <- "/Users/lgarzio/Documents/repo/R_scripts" # location to save output
username <- "OOIAPI-D8S960UXPK4K03"
token <- "IXL48EQ2XY"

# Specify reference designator of interest. Information can be found at ooi.visualocean.net
refdes <- "GA03FLMA-RIM01-02-CTDMOG040"

# Constrain dates for annotation request. Use "" to request the full time-range available in the system.
#beginDT <- '2015-11-25T19:21:00.000Z'
#endDT <- '2016-11-05T18:58:00.000Z'
beginDT <- ""
endDT <- ""

endpoint <- AnnoRequestURL(refdes, beginDT, endDT)
r_text <- SendAnnotationRequest(endpoint, username, token)
print(r_text)

# Currently excluding "parameters" from the annotations output. fromJSON() doesn't know how to deal with a field
# that is [ ] (as "parameters" often is), so it reads that field as NULL, then write.table and write.csv throw errors.
# Need to figure this out.
cols <- c("source", "id", "subsite", "node", "sensor", "stream", "method", "beginDT", "endDT", 
          "exclusionFlag", "qcFlag", "annotation")
fname = paste(refdes, "annotations.csv", sep="_")
write.table(r_text[cols], file = paste(sdir, fname, sep="/"), row.names = FALSE, sep=",")