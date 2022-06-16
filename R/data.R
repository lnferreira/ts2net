#' Monthly temperatures in 27 US cities.
#'
#' A data set containing the temperature in 27 US cities from 2012 and 2017. This data set
#' was adapted from the original and considers only cities in the US. Data was grouped by
#' month (mean value) and removed days with missing data.
#'
#' @format A data frame with 61 rows and 28 variables:
#' \describe{
#'   \item{date}{First day of each month. The temperatures correspond to the mean values of each month }
#'   \item{other columns}{Temperature (ºC) time series in each city}
#' }
#' @docType data
#' @keywords dataset
#' @author David Beniaguev
#' @note This data set is released under the Database Contents License (DbCL) v1.0.
#' @source \url{https://www.kaggle.com/datasets/selfishgene/historical-hourly-weather-data}
"us_cities_temperature_df"

#' Monthly temperatures in 27 US cities.
#'
#' A data set containing the temperature in 27 US cities from 2012 and 2017. This data set
#' was adapted from the original and considers only cities in the US. Data was grouped by
#' month (mean value) and removed days with missing data.
#'
#' @format A list with a time series for each city. For the dates, check us_cities_temperature_df
#'   data set.
#' @docType data
#' @keywords dataset
#' @author David Beniaguev
#' @note This data set is released under the Database Contents License (DbCL) v1.0.
#' @source \url{https://www.kaggle.com/datasets/selfishgene/historical-hourly-weather-data}
"us_cities_temperature_list"


#' Sin-Cos data set generator. This function generates a set of sine and cosine
#' time series. This function is used as example of the package application.
#'
#' @param num_sin_series Integer. Number of sine time series
#' @param num_cos_series Integer. Number of cosine time series
#' @param x_max Float. Max x value in sin(x) or cor(x).
#' @param ts_length Integer. Time series length.
#' @param jitter_amount Float. The total amount of jitter added to each time series.
#' @param return_x_values Boolean. If positive, returns a list of
#' data frames with x and y values.
#'
#' @return A list with all time series. First the num_sin_series sine time series
#' followed by the num_cos_series cosine time series.
#' @export
dataset_sincos_generate <- function(num_sin_series = 25, num_cos_series = 25,
                                    x_max = 8 * pi, ts_length = 100,
                                    jitter_amount = 0.1, return_x_values=FALSE) {
    x = seq(0, x_max, length.out=ts_length)
    sin_tss = list()
    cos_tss = list()
    if (num_sin_series > 0)
        sin_tss = replicate(num_sin_series, {jitter(sin(x), amount = jitter_amount)}, simplify = FALSE)
    if (num_cos_series > 0)
        cos_tss = replicate(num_cos_series, {jitter(cos(x), amount = jitter_amount)}, simplify = FALSE)
    ds = c(sin_tss, cos_tss)
    if (return_x_values)
        ds = lapply(ds, function(y) data.frame(x=x, y=y))
    ds
}


#' Random event time series generator
#'
#' It generates an event time series with length ts_length with
#' num_events events considering a uniform probability distribution.
#'
#' @param ts_length Time series Length
#' @param num_events The number of events
#' @param return_marked_times Return the time indices (marked points) where
#'   the events occur.
#'
#' @return An event (binary, 1: event, 0 otherwise) time series
#' @export
random_ets <- function(ts_length, num_events, return_marked_times=FALSE) {
    if (num_events > ts_length) {
        warning("Desired number of events (", num_events, ") larger
                than desired time series length (", ts_length, "). Returning ",
                ts_length, " events.")
        num_events = ts_length
    }
    ets = array(0, ts_length)
    ets[sample(ts_length, num_events)] = 1
    if (return_marked_times)
        ets = which(ets == 1)
    ets
}
