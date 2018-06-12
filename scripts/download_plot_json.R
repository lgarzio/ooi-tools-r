# author: Lori Garzio
# Download data via the OOI API in a synchronous (instantaneous) request and plot a timeseries. Useful to quickly look at data.
# 2018-06-12
# refs: https://www.r-bloggers.com/accessing-apis-from-r-and-a-little-r-programming/
# helpful resource: ooi.visualocean.net

# Load required packages
library(httr)
library(jsonlite)
library(plotly)
library(webshot)

# ----------------------------------------Functions----------------------------------------

# Return a data request url
DataRequestUrl <- function(subsite, node, sensor, method, stream, beginDT, endDT) {
  base <- 'https://ooinet.oceanobservatories.org/api/m2m/12576/sensor/inv'
  url <- paste(base,subsite,node,sensor,method,stream,sep='/')
  
  # Adding ?limit=xxx to the data request url tells the system to supply a synchronous (instantaneous)
  # response and the data will be delivered in the GET response. Here we are limiting to 2000 data points.
  if (nchar(beginDT) == 0 & nchar(endDT) == 0) {
    endpoint <- paste(url,'&limit=1000',sep='')
  } else {
    endpoint <- paste(url,'?beginDT=',beginDT,'&endDT=',endDT,'&limit=2000',sep='')
  } 
  
  return(endpoint)
}

SendDataRequest <- function(url, username, token) {
  response <- GET(url, authenticate(username, token))
  
  if (response$status_code == 200) {
    print("Request successful!")
  } else {
    stop(
      sprintf("Request unsuccessful. status_code %s %s", response$status_code, r_text$message$status)
    )
  }
  
  df <- fromJSON((content(response, 'text')), flatten = TRUE)
  return(df)
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

# Return a data frame containing data
df <- SendDataRequest(data_request_url, username, token)
ctime <- as.POSIXct(df$time, origin = "1900-01-01", tz = "UTC")
df['ctime'] <- ctime  # add formatted date as another column in the data frame

# Loop through the science variables in the file and plot.
# More info on streams and variables can be found at ooi.visualocean.net
ctd_vars <- c("ctdmo_seawater_pressure", "ctdmo_seawater_conductivity", "ctdmo_seawater_temperature",
                 "practical_salinity", "density")
ctd_units <- list("dbar", "S m-1", "deg_C", "1", "kg m-3")
ctd_info <- cbind(ctd_vars, ctd_units)

for (i in 1:length(ctd_vars)){
  var = ctd_info[i,]$ctd_vars
  var_units = ctd_info[i,]$ctd_units
  
  # Only reverse the y-axis if plotting pressure
  if (var == "ctdmo_seawater_pressure") {
    yax <- list(title = sprintf("%s (%s)", var, var_units), showline = TRUE, autorange = "reversed")
  } else {
    yax <- list(title = sprintf("%s (%s)", var, var_units), showline = TRUE)
  }

  # Note: plotly files can be saved as interactive web-based graphs. See https://plot.ly/r/getting-started/
  # However here I'm saving the plots as local .png files using the export() function with the webshot 
  # package: https://github.com/wch/webshot/  
  
  p <- plot_ly(df, x = df$ctime, y = df[[var]], type = "scatter", mode = "markers") %>%
    layout(title = sprintf("%s-%s-%s", subsite, node, sensor), xaxis = list(showline = TRUE), yaxis = yax)
  export(p, file = paste(sdir, sprintf("%s-%s-%s_%s.png", subsite, node, sensor, var), sep="/"))
}