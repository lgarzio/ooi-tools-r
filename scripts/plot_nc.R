# author: Lori Garzio
# 2018-06-11

# Load required packages
library(ncdf4)
library(tools)
library(lubridate)
library(plotly)
library(webshot)

sdir <- "/Users/lgarzio/Documents/repo/R_scripts" # location to save output

fname <- "https://opendap.oceanobservatories.org/thredds/dodsC/ooi/ooidatateam@gmail.com/20180608T142549-GA03FLMA-RIM01-02-CTDMOG040-recovered_inst-ctdmo_ghqr_instrument_recovered/deployment0002_GA03FLMA-RIM01-02-CTDMOG040-recovered_inst-ctdmo_ghqr_instrument_recovered_20151125T193001-20161105T184501.nc"
f <- nc_open(fname)
 
# Get the name of the file and the reference designator
ff <- strsplit(fname, '/')[[1]][9]
refdes <- substr(ff, 16, 42)

# Print all of the variable names in the file
vars <- names(f$var)
vars

# Get information on time from the file
t <- ncvar_get(f, "time")
t_units <- ncatt_get(f, "time", "units")$value
t_units
time <- as.POSIXct(t, origin = "1900-01-01", tz = "UTC")
rtime_hour <- round_date(time, unit = "hour")

# Loop through the science variables in the file and plot.
# More info on streams and variables can be found at ooi.visualocean.net

ctd_vars <- list("ctdmo_seawater_pressure", "ctdmo_seawater_conductivity", "ctdmo_seawater_temperature",
                 "practical_salinity", "density")

for (var in ctd_vars){
  var_att <- ncatt_get(f, var)
  var_att
  var_units <- var_att$units
  var_data <- ncvar_get(f, var)
  
  # Make a quick plot
  qplot(time, var_data, xlab = "", ylab = sprintf("%s (%s)", var, var_units))
  
  # Get the hourly average
  havg <- setNames(aggregate(var_data, list(rtime_hour), mean, na.rm = TRUE), c("time_hh", "var_data_mean"))
  qplot(havg$time_hh, havg$var_data_mean)
  
  # Make a nicer plot of the hourly averaged data
  # Only reverse the y-axis if plotting pressure
  if (var == "ctdmo_seawater_pressure") {
    yax <- list(title = sprintf("%s (%s)", var, var_units), showline = TRUE, autorange = "reversed")
  } else {
    yax <- list(title = sprintf("%s (%s)", var, var_units), showline = TRUE)
  }
    
  p <- plot_ly(havg, x = havg$time_hh, y = havg$var_data_mean, type = "scatter", mode = "markers") %>%
    layout(title = sprintf("%s (hourly averaged)", refdes), xaxis = list(showline = TRUE), yaxis = yax)
  export(p, file = paste(sdir, sprintf("%s_%s.png", file_path_sans_ext(ff), var), sep="/"))
}