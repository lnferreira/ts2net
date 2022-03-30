#' Normalize a distance/similarity matrix.
#'
#' @param D Distance/similarity matrix
#' @param to An array of two elements c(min_value, max_value) representing
#'    the interval where the elements of dist_matrix will be normalized to.
#'
#' @return Normalized matrix
#' @importFrom scales rescale
#' @export
dist_matrix_normalize <- function(D, to=c(0,1)) {
    distNorm = matrix(0, nrow(D), ncol(D))
    d = D[upper.tri(D)]
    d = rescale(d, to = to)
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


#' Extract events from a time series.
#'
#' This function transforms an time series (array) into a binary time series
#' where 1 means a event and 0 means no event.
#'
#' @param ts Array. Time series
#' @param th A threshold (if `method=greater_than` or `=lower_than`), or the
#'   percentile (if `method=top_percentile` or `=lower_percentile`), or the
#'   total number (if `method=highest` or `=lowest`).
#' @param method String. One of following options:
#'   * `greater_than`: All values greater or equal to `th`.
#'   * `lower_than`: All values lower or equal to `th`.
#'   * `top_percentile`: Values greater than the `th` percentile.
#'   * `highest`: The top `th` values.
#'   * `lowest`: The lower `th` values.
#'
#' @return An event (binary, 1: event, 0 otherwise) time series
#' @export
events_from_ts <- function(ts, th, method=c("greater_than", "lower_than",
                                                "top_percentile", "lower_percentile",
                                                "highest", "lowest")) {
    events_method = match.arg(method)
    events_ts = rep(0, length(ts))
    if (events_method %in% c("top_percentile", "lower_percentile")) {
        if (missing(th) | th < 0 | th > 1)
            stop("Please inform the percentile th = [0,1].")
    } else if (events_method %in% c("greater_than", "lower_than")) {
        if (missing(th))
            stop("Please inform the threshold th.")
    } else if (events_method %in% c("highest", "lowest")) {
        if (missing(th))
            stop("Please inform the desired number of ", events_method, "values.")
        if (th < 0 | th > length(ts))
            stop("Please inform a valid number of ", events_method, "values.")
    }
    switch(events_method,
           greater_than = {
               events_ts[ts >= th] = 1
               },
           lower_than = {
               events_ts[ts <= th] = 1
               },
           top_percentile = {
               events_ts[ts >= quantile(ts, probs = 1 - th)] = 1
           },
           lower_percentile = {
               events_ts[ts >= quantile(ts, probs = th)] = 1
           },
           highest = {
               events_ts[order(ts1, decreasing = T)[1:th]] = 1
           },
           lowest = {
               events_ts[order(ts1)[1:th]] = 1
           })
    events_ts
}

