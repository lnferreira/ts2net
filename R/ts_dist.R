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
dist_parallel <- function(tsList, measureFunc=tsdiss_euclidean, isSymetric=TRUE,
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
    dists = parallel::mclapply(combs, function(ids){
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

#' Normalize a distance/similarity matrix
#'
#' @param dist_matrix Distance/similarity matrix
#' @param to An array of two elements c(min_value, max_value) representing
#'    the interval where the elements of dist_matrix will be normalized to.
#'
#' @return Normalized matrix
#' @export
dist_matrix_normalize <- function(dist_matrix, to=c(0,1)) {
    distNorm = matrix(0, nrow(dist_matrix), ncol(dist_matrix))
    d = dist_matrix[upper.tri(dist_matrix)]
    d = scales::rescale(d, to = to)
    distNorm[upper.tri(distNorm)] = d
    distNorm = distNorm + t(distNorm)
    colnames(distNorm) = colnames(dist_matrix)
    rownames(distNorm) = rownames(dist_matrix)
    distNorm
}


#' Correlation distance
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
