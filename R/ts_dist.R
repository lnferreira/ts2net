#' Calculate distances between pairs of time series in a list.
#'
#' This function calculates the distance between all combinations of
#' time series in the list and returns a distance matrix. This function
#' is usually the first try and might work if the number of time series
#' and their length are not too big.
#'
#' @param tsList List of time series (arrays).
#' @param measureFunc Function to be applied to all combinations
#'     of time series. This function should have at least two parameters
#'     for each time series. Ex: function(ts1, ts2){ cor(ts1, ts2) }
#' @param isDist Boolean. If measureFunc is a distance function. iF TRUE,
#'     a zero value returned by measureFunc(ts1,ts2) means that the pair
#'     of time series ts1 and ts2 are perfectly equal.
#' @param isSymetric Boolean. If the distance function is symmetric.
#' @param num_cores Numeric. Number of cores
#' @param error_value The value returned if an error occur when calculating a
#'     the distance for a pair of time series.
#' @param warn_error Boolean. If TRUE (default), a warning will rise when an
#'     error occur during the calculations.
#' @param ... Additional parameters for measureFunc
#'
#' @return A distance or similarity matrix M whose position M_{ij}
#'     corresponds to distance or similarity value between time series
#'     i and j.
#' @export
ts_dist <- function(tsList, measureFunc=tsdist_cor, isSymetric=TRUE,
                          error_value=NaN, warn_error=TRUE, num_cores=1, ...) {
    measureFuncCompiled <- compiler::cmpfun(measureFunc)
    tsListLength = length(tsList)
    combs = c()
    if (isSymetric){
        combs = combn(tsListLength, 2, simplify = FALSE)
    } else {
        combs = as.matrix(expand.grid(1:tsListLength, 1:tsListLength))
        combs = lapply(1:nrow(combs), function(i) combs[i,])
    }
    dists = mclapply(combs, function(ids){
        tryCatch({
            measureFuncCompiled(tsList[[ids[1]]], tsList[[ids[2]]], ...)
        }, error=function(cond) {
            if (warn_error)
                warning("Error when calculating distance between time series ", ids[1], " and ", ids[2])
            error_value
        })
    }, mc.cores = num_cores)
    dist_matrix = matrix(0, tsListLength, tsListLength)
    if (isSymetric){
        dist_matrix[lower.tri(dist_matrix)] = unlist(dists)
        dist_matrix = as.matrix(as.dist(dist_matrix))
    } else {
        for (i in 1:length(combs))
            dist_matrix[combs[[i]][1], combs[[i]][2]] = dists[[i]]
    }
    dist_matrix
}


#' Normalize a distance/similarity matrix.
#'
#' @param D Distance/similarity matrix
#' @param to An array of two elements c(min_value, max_value) representing
#'    the interval where the elements of dist_matrix will be normalized to.
#'
#' @return Normalized matrix
#' @export
dist_matrix_normalize <- function(D, to=c(0,1)) {
    distNorm = matrix(0, nrow(D), ncol(D))
    d = D[upper.tri(D)]
    d = scales::rescale(d, to = to)
    distNorm[upper.tri(distNorm)] = d
    distNorm = distNorm + t(distNorm)
    colnames(distNorm) = colnames(D)
    rownames(distNorm) = rownames(D)
    distNorm
}


#' Returns the distance value that corresponds to the desired percentile. This function
#' is useful when the user wants to generate networks with different distance functions
#' but with the same link density.
#'
#' @param D distance matrix
#' @param percentile (Float) The desired percentile of lower distances.
#' @param is_D_symetric (Boolean)
#'
#' @return Distance percentile value.
#' @export
dist_percentile <- function(D, percentile = 0.1, is_D_symetric=TRUE) {
    D[is.na(D)] = +Inf
    d = D
    if (is_D_symetric){
        d = D[upper.tri(D)]
    } else {
        d = D[upper.tri(D) | lower.tri(D)]
    }
    quantile(d, probs = c(percentile))
}


#' Absolute correlation distance.
#'
#' Calculates 1 - abs(cor(ts1, ts2)). Different from tsdist_cor, this distance
#' considers both strong positive and negative correlations. Zero means no
#' correlation.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#'
#' @return Real value [0,1] where 0 means perfect positive or negative correlation
#' and 1 no  correlation.
#' @export
tsdist_cor_abs <- function(ts1, ts2) {
    1 - abs(cor(ts1, ts2))
}


#' Positive or negative correlation distance.
#'
#' Perfect positive returns zero and one means no  or negative correlations. The
#' opposite occurs if positive_cor==F.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param positive_cor Boolean. If TRUE (default), only positive correlations are considered.
#' If FALSE, only negative correlations are considered.
#'
#' @return Real value [0,1] where 0 means perfect positive (or negative
#' if positive_cor==F) correlation and 1 no positive (or negative
#' if positive_cor==F) correlation.
#' @export
tsdist_cor <- function(ts1, ts2, positive_cor=TRUE) {
    r = cor(ts1, ts2)
    if (!positive_cor)
        r = r * -1
    1 - pmax(0, r)
}


#' Cross-correlation distance
#'
#' Minimum correlation distance considering a +- lag máxium (lag_max)
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param type String. "correlation" or "covariance" to be used (type) in the ccf function.
#' @param cor_type String. "abs" (default), "positive", or "negative". "Abs" considers the
#'   correlation absolute value. "positive" only positve correlations and "negative" only
#'   negative correlations.
#' @param directed Boolean. If FALSE (default), the lag interval [-lag_max,+lag_max] is
#'   considered. Otherwise, [-lag_max,0] is considered.
#' @param lag_max Integer. Default = 10.
#' @param return_lag Also returns the time lag that leads to the shortest distances.
#'
#' @return Distance
#' @export
tsdist_ccf <- function(ts1, ts2, type=c("correlation", "covariance"),
                                    cor_type="abs",
                                    directed=F, lag_max = 10, return_lag=F) {
    cc = ccf(ts1, ts2, lag.max = lag_max, plot = F, type = type[1])
    cc_acfs = cc$acf[,,1]
    cc_lags = cc$lag[,,1]
    if (directed) {
        cc_acfs = cc_acfs[cc_lags <= 0]
        cc_lags = cc_lags[cc_lags <= 0]
    }
    if (cor_type == "positive")
        cc_acfs[cc_acfs < 0] = 0
    if (cor_type == "negative")
        cc_acfs[cc_acfs > 0] = 0
    cc_acfs = abs(cc_acfs)
    cc_max_index = which.max(cc_acfs)
    cc_max = cc_acfs[cc_max_index]
    cc_max_lag = cc_lags[cc_max_index]
    dist = 1 - abs(cc_max)
    if (return_lag)
        dist = data.frame(dist=dist, lag=cc_max_lag)
    dist
}


#' Dynamic Time Warping (DTW) distance.
#'
#' This function is a wrapper for the dtw() function from the dtw package.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#'
#' @return DTW distance
#' @importFrom dtw dtw
#' @export
tsdist_dtw <- function(ts1, ts2) {
    dtw(ts1,ts2)$distance
}
