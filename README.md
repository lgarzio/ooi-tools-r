# ooi-tools-r
This is a collection of basic tools to work with data from the Ocean Observatories Initiative (OOI) using R.

### Getting Started

To use the OOI API, you will need an API Username and Password. Register for an account at https://ooinet.oceanobservatories.org/, you can find your username and password in your User Profile (click on your username in the top right corner).

The [Datateam Database](http://ooi.visualocean.net/) is a good resource to find the components you will need to make API data requests (reference designator, stream, method) and to find data product descriptions and units.

### Scripts
- [download_nc.R](https://github.com/lgarzio/ooi-tools-r/blob/master/scripts/download_nc.R): Download data in NetCDF file format (asynchronous request) via the OOI API. The data will be processed and served via THREDDs.

- [download_plot_json.R](https://github.com/lgarzio/ooi-tools-r/blob/master/scripts/download_nc.R): Download data via the OOI API in a synchronous (instantaneous) request and plot a timeseries. Useful to quickly look at data.

- [plot_nc_timeseries.R](https://github.com/lgarzio/ooi-tools-r/blob/master/scripts/plot_nc.R): Quickly plot a timeseries from a NetCDF file.