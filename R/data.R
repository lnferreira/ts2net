
#' Sin-Cos data set generator. This function generates a set of sine and cosine
#' time series. This function is used as example of the package application.
#'
#' @param num_sin_series Integer. Number of sine time series
#' @param num_cos_series Integer. Number of cosine time series
#' @param x_max Float. Max x value in sin(x) or cor(x).
#' @param ts_length Integer. Time series length.
#' @param jitter_amount Float. The total amount of jitter added to each time series.
#' @param return_x_values Boolean. If positive (default), returns a list of
#' data frames with x and y values.
#'
#' @return A list with all time series. First the num_sin_series sine time series
#' followed by the num_cos_series cosine time series.
#' @export
dataset_sincos_generate <- function(num_sin_series = 25, num_cos_series = 25,
                                    x_max = 8 * pi, ts_length = 100,
                                    jitter_amount = 0.1, return_x_values=TRUE) {
    x = seq(0, x_max, length.out=ts_length)
    sin_tss = list()
    cos_tss = list()
    if (num_sin_series > 0)
        sin_tss = replicate(num_sin_series, {jitter(sin(x), amount = jitter_amount)}, simplify = F)
    if (num_cos_series > 0)
        cos_tss = replicate(num_cos_series, {jitter(cos(x), amount = jitter_amount)}, simplify = F)
    ds = c(sin_tss, cos_tss)
    if (return_x_values)
        ds = lapply(ds, function(y) data.frame(x=x, y=y))
    ds
}
