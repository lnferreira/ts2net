#' Calculate distances between pairs of time series in a list.
#'
#' This function calculates the distance between all combinations of
#' time series in the list and returns a distance matrix. This function
#' is usually the first try and might work if the number of time series
#' and their length are not too big.
#'
#' @param ts_list List of time series (arrays).
#' @param dist_func Function to be applied to all combinations
#'     of time series. This function should have at least two parameters
#'     for each time series. Ex: function(ts1, ts2){ cor(ts1, ts2) }
#' @param is_symetric Boolean. If the distance function is symmetric.
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
#' @import igraph parallel utils
#' @importFrom compiler cmpfun
#' @importFrom utils combn
#' @export
ts_dist <- function(ts_list, dist_func=tsdist_cor, is_symetric=TRUE,
                          error_value=NaN, warn_error=TRUE, num_cores=1, ...) {
    measureFuncCompiled <- cmpfun(dist_func)
    tsListLength = length(ts_list)
    combs = c()
    if (is_symetric){
        combs = combn(tsListLength, 2, simplify = FALSE)
    } else {
        combs = as.matrix(expand.grid(1:tsListLength, 1:tsListLength))
        combs = lapply(1:nrow(combs), function(i) combs[i,])
    }
    dists = mclapply(combs, function(ids){
        tryCatch({
            measureFuncCompiled(ts_list[[ids[1]]], ts_list[[ids[2]]], ...)
        }, error=function(cond) {
            if (warn_error)
                warning("Error when calculating distance between time
                        series ", ids[1], " and ", ids[2])
            error_value
        })
    }, mc.cores = num_cores)
    dist_matrix = matrix(0, tsListLength, tsListLength)
    if (!is.null(names(ts_list)))
        colnames(dist_matrix) = rownames(dist_matrix) = names(ts_list)
    if (is_symetric){
        dist_matrix[lower.tri(dist_matrix)] = unlist(dists)
        dist_matrix = as.matrix(as.dist(dist_matrix))
    } else {
        for (i in 1:length(combs))
            dist_matrix[combs[[i]][1], combs[[i]][2]] = dists[[i]]
    }
    dist_matrix
}

#' Calculate distances between pairs of time series in part of a list.
#'
#' This function is particularly useful to run in parallel as jobs in a
#' cluster (HPC). It returns a data frame with elements (i,j) and a distance
#' value calculated for the time series i and j. Not all the elements are
#' calculated but just a a part of the total combinations of time series in the
#' list. This function load all the time series in the memory to make the
#' calculations faster. However, if the time series are too long and/or the
#' dataset is huge, it might represent a memory problem. In this case,
#' dist_dir_parallel() is more recommended.
#'
#' @param ts_list List of time series.
#' @param num_part Numeric positive between 1 and the total number of parts
#'     (num_total_parts). This value corresponds to the part (chunk) of the
#'     total number of parts to be calculated.
#' @param num_total_parts Numeric positive corresponding the total number of
#'     parts.
#' @param combinations A list composed by arrays of size 2 indicating the
#'     files indices to be compared. If this parameter is passed, then
#'     the function does not split all the possibilities and does not use
#'     the parameters num_part and num_total_parts. This parameter is useful
#'     when the number of combinations is very high and this functions is
#'     called several times (high num_total_parts). In this case, instead of
#'     calculating all the combinations in each call, the user can calculate
#'     it once and pass it via this parameter.
#' @param dist_func Function to be applied to all combinations
#'     of time series. This function should have at least two parameters
#'     for each time series. Ex: function(ts1, ts2){ cor(ts1, ts2) }
#' @param isSymetric Boolean. If the distance function is symmetric.
#' @param num_cores Numeric. Number of cores
#' @param simplify Boolean. If FALSE, returns a list of one (if
#'     isSymetric == FALSE) or two elements (if isSymetric == TRUE).
#' @param error_value The value returned if an error occur when calculating a
#'     the distance for a pair of time series.
#' @param warn_error Boolean. If TRUE (default), a warning will rise when an
#'     error occur during the calculations.
#' @param ... Additional parameters for measureFunc
#'
#' @return A data frame with elements (i,j) and a distance value calculated
#'     for the time series i and j.
#' @importFrom compiler cmpfun
#' @export
ts_dist_part <- function(ts_list, num_part, num_total_parts, combinations, dist_func=tsdist_cor,
                         isSymetric=TRUE, error_value=NaN, warn_error=TRUE, simplify=TRUE, num_cores=1, ...) {
    measureFuncCompiled <- cmpfun(dist_func)
    tsListLength = length(ts_list)
    combs = c()
    if (missing(combinations)) {
        if (isSymetric){
            combs = combn(tsListLength, 2, simplify = FALSE)
        } else {
            combs = as.matrix(expand.grid(1:tsListLength, 1:tsListLength))
            combs = lapply(1:nrow(combs), function(i) combs[i,])
        }
        combs = split(combs, ceiling(seq_along(combs)/(length(combs) / num_total_parts)))[[num_part]]
    } else {
        combs = combinations
    }
    dists = parallel::mclapply(combs, function(ids){
        d = tryCatch({
            measureFuncCompiled(ts_list[[ids[1]]], ts_list[[ids[2]]], ...)
        }, error=function(cond) {
            if (warn_error)
                warning("Error when calculating distance between time series ", ids[1], " and ", ids[2])
            error_value
        })
        if (isSymetric){
            r = data.frame(i=c(ids[1], ids[2]), j=c(ids[2], ids[1]) , dist=rep(d, 2))
        } else {
            r = data.frame(i=ids[1], j=ids[2], dist=d)
        }
        r
    }, mc.cores = num_cores)
    if (simplify)
        dists = do.call(rbind, dists)
    dists
}

#' Calculate distances between pairs of time series stored in files.
#'
#' This function works similarly as dist_parts_parallel(). The difference is that it
#' reads the time series from RDS files in a directory. The advantage of this approach
#' is that it does not load all the time series in memory but reads them only when
#' necessary. This means that this function requires much less memory and should be
#' preferred when memory consumption is a concern, e.g., huge data set or very long
#' time series. The disadvantage of this approach is that it requires a high number of
#' file read operations which considerably takes more time during the calculations.
#' IMPORTANT: the file order is very important so it is highly recommended to use
#' numeric names, e.g., 0013.RDS.
#'
#' @param input_dir Directory path for the directory with time series files (RDS)
#' @param num_part Numeric positive between 1 and the total number of parts
#'     (num_total_parts). This value corresponds to the part (chunk) of the
#'     total number of parts to be calculated.
#' @param num_total_parts Numeric positive corresponding the total number of
#'     parts.
#' @param combinations A list composed by arrays of size 2 indicating the
#'     files indices to be compared. If this parameter is passed, then
#'     the function does not split all the possibilities and does not use
#'     the parameters num_part and num_total_parts.
#' @param measureFunc Function to be applied to all combinations
#'     of time series. This function should have at least two parameters
#'     for each time series. Ex: function(ts1, ts2){ cor(ts1, ts2) }
#' @param isSymetric Boolean. If the distance function is symmetric.
#' @param num_cores Numeric. Number of cores
#' @param simplify Boolean. If FALSE, returns a list of one (
#'     if isSymetric == FALSE) or two elements (if isSymetric == TRUE).
#' @param error_value The value returned if an error occur when calculating a
#'     the distance for a pair of time series.
#' @param warn_error Boolean. If TRUE (default), a warning will rise when an
#'     error occur during the calculations.
#' @param ... Additional parameters for measureFunc
#'
#' @return A data frame with elements (i,j) and a distance value calculated
#'     for the time series i and j. Each index corresponds to the order
#'     where the files are listed.
#'
#' @importFrom compiler cmpfun
#' @export
ts_dist_part_file <- function(input_dir, num_part, num_total_parts, combinations, measureFunc=tsdist_cor,
                       isSymetric=TRUE, error_value=NaN, warn_error=TRUE, simplify=TRUE, num_cores=1, ...) {
    measureFuncCompiled <- cmpfun(measureFunc)
    list_files = list.files(path = input_dir, full.names = TRUE, pattern = "RDS")
    ts_list_length = length(list_files)
    combs = c()
    if (missing(combinations)) {
        if (isSymetric){
            combs = combn(ts_list_length, 2, simplify = FALSE)
        } else {
            combs = as.matrix(expand.grid(1:ts_list_length, 1:ts_list_length))
            combs = lapply(1:nrow(combs), function(i) combs[i,])
        }
        combs = split(combs, ceiling(seq_along(combs)/(length(combs) / num_total_parts)))[[num_part]]
    } else {
        combs = combinations
    }
    dists = parallel::mclapply(combs, function(ids){
        d = tryCatch({
            ts1 = readRDS(list_files[ids[1]])
            ts2 = readRDS(list_files[ids[2]])
            measureFuncCompiled(ts1, ts2, ...)
        }, error=function(cond) {
            if (warn_error)
                warning("Error when calculating distance between time series ", ids[1], " and ", ids[2])
            error_value
        })
        if (isSymetric){
            r = data.frame(i=c(ids[1], ids[2]), j=c(ids[2], ids[1]) , dist=rep(d, 2))
        } else {
            r = data.frame(i=ids[1], j=ids[2], dist=d)
        }
        r
    }, mc.cores = num_cores)
    if (simplify)
        dists = do.call(rbind, dists)
    dists
}


#' Absolute, positive, or negative correlation distance.
#'
#' Considering r the person correlation coefficient, this function returns
#' either 1 - abs(r) if cor_type=="abs", 1 - pmax(0, r) if cor_type == "+",
#' or 1 - pmax(0, r * -1) if cor_type == "-". Another possibility is to
#' run a significance test to verify if the r is significant.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param cor_type String. "abs" (default), "+", or "-". "abs" considers the
#'   correlation absolute value. "+" only positive correlations and "-" only
#'   negative correlations.
#' @param sig_test Run a statistical test. Return 0 if significant or 1 otherwise.
#' @param sig_level The significance level to test if correlation is significant.
#' @param ... Additional parameters to cor.test() function.
#'
#' @importFrom stats cor.test
#' @return Real value [0,1] where 0 means perfect positive (or negative
#' if positive_cor==FALSE) correlation and 1 no positive (or negative
#' if positive_cor==FALSE) correlation.
#' @export
tsdist_cor <- function(ts1, ts2, cor_type="abs", sig_test=FALSE, sig_level=0.01, ...) {
    r_test = cor.test(ts1, ts2, ...)
    r = as.numeric(r_test$estimate)
    d_cor = 1
    if (sig_test) {
        if (!is.na(r_test$p.value) && r_test$p.value <= sig_level) {
            if ((cor_type == "+" & r > 0) | (cor_type == "-" & r < 0))
                d_cor = 0
            if (cor_type != "+" & cor_type != "-")
                d_cor = 0
        }
    } else {
        if (cor_type == "+") {
            d_cor = 1 - pmax(0, r)
        } else if (cor_type == "-") {
            d_cor = 1 - pmax(0, r * -1)
        } else {
            d_cor = 1 - abs(r)
        }
    }
    d_cor
}


#' Cross-correlation distance
#'
#' Minimum correlation distance considering a +- max lag  (lag_max)
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param type String. "correlation" or "covariance" to be used (type) in the ccf function.
#' @param cor_type String. "abs" (default), "+", or "-". "abs" considers the
#'   correlation absolute value. "+" only positive correlations and "-" only
#'   negative correlations.
#' @param directed Boolean. If FALSE (default), the lag interval [-lag_max,+lag_max] is
#'   considered. Otherwise, [-lag_max,0] is considered.
#' @param lag_max Integer. Default = 10.
#' @param return_lag Also returns the time lag that leads to the shortest distances.
#'
#' @importFrom stats ccf
#' @return Distance
#' @export
tsdist_ccf <- function(ts1, ts2, type=c("correlation", "covariance"),
                                    cor_type="abs",
                                    directed=FALSE, lag_max = 10, return_lag=FALSE) {
    cc = ccf(ts1, ts2, lag.max = lag_max, plot = FALSE, type = type[1])
    cc_acfs = cc$acf[,,1]
    cc_lags = cc$lag[,,1]
    if (directed) {
        cc_acfs = cc_acfs[cc_lags <= 0]
        cc_lags = cc_lags[cc_lags <= 0]
    }
    if (cor_type == "+")
        cc_acfs[cc_acfs < 0] = 0
    if (cor_type == "-")
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


#' Variation of Information distance
#'
#' The variation of information (VoI) is a distance function based on mutual
#' information.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param nbins The number of bins used for the discretization of both time series.
#'   It can be a positive integer or a string with one of the three rules
#'   "sturges" (default), "freedman-diaconis", or "scott".
#' @param method The name of the entropy estimator used in the functions
#'   mutinformation() and entropy() from the infotheo package.
#'
#' @return Distance
#' @export
#' @importFrom infotheo discretize mutinformation entropy
tsdist_voi <- function(ts1, ts2, nbins = c("sturges", "freedman-diaconis", "scott"),
                       method="emp") {
    ts_bin = ts1
    if (length(ts2) > length(ts1))
        ts_bin = ts2
    if (is.character(nbins))
        nbins = match.arg(nbins)
    if (nbins == "sturges") {
        nbins = nclass.Sturges(ts_bin)
    } else if (nbins == "freedman-diaconis") {
        nbins = nclass.FD(ts_bin)
    } else if (nbins == "scott") {
        nbins = nclass.scott(ts_bin)
    }
    ts1b = discretize(ts1, nbins = nbins)
    ts2b = discretize(ts2, nbins = nbins)
    i = mutinformation(ts1b, ts2b, method = method)
    h1 = entropy(ts1b, method = method)
    h2 = entropy(ts2b, method = method)
    h1 + h2 - 2 * i
}


#' Normalized mutual information distance
#'
#' Calculates the normalized mutual information (NMI) and returns it as distance
#' 1 - NMI.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param nbins The number of bins used for the discretization of both time series.
#'   It can be a positive integer or a string with one of the three rules
#'   "sturges" (default), "freedman-diaconis", or "scott".
#' @param normalization The mutual information (I) normalization method.
#'   Options are "sum" (default) 1-(2I/(h1+h2)), "min" 1-(I/min(h1,h2)), "max"
#'   1-(I/max(h1,h2)), and "sqrt" 1-(I/sqrt(h1*h2)).
#' @param method The name of the entropy estimator used in the functions
#'   mutinformation() and entropy() from the infotheo package.
#'
#' @importFrom infotheo discretize mutinformation entropy
#' @importFrom grDevices nclass.Sturges nclass.FD nclass.scott
#' @return Distance
#' @export
tsdist_nmi <- function(ts1, ts2, nbins = c("sturges", "freedman-diaconis", "scott"),
                       normalization = c("sum", "min", "max", "sqrt"),
                       method = "emp") {
    ts_bin = ts1
    if (length(ts2) > length(ts1))
        ts_bin = ts2
    if (is.character(nbins))
        nbins = match.arg(nbins)
    if (nbins == "sturges") {
        nbins = nclass.Sturges(ts_bin)
    } else if (nbins == "freedman-diaconis") {
        nbins = nclass.FD(ts_bin)
    } else if (nbins == "scott") {
        nbins = nclass.scott(ts_bin)
    }
    ts1b = discretize(ts1, nbins = nbins)
    ts2b = discretize(ts2, nbins = nbins)
    i = mutinformation(ts1b, ts2b, method = method)
    h1 = entropy(ts1b, method = method)
    h2 = entropy(ts2b, method = method)
    normalization = match.arg(normalization)
    normalization <- switch(normalization,
                sum = 0.5 * (h1 + h2),
                min = min(h1, h2),
                max = max(h1, h2),
                sqrt = sqrt(h1 * h2))
    1 - (i/normalization)
}



#' Maximal information coefficient (MIC) distance.
#'
#' This function transforms the MIC function (from minerva package) into
#' a distance function.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#'
#' @return Distance
#' @export
#' @importFrom minerva mine
tsdist_mic <- function(ts1, ts2) {
    1 - mine(ts1, ts2)$MIC
}


#' Dynamic Time Warping (DTW) distance.
#'
#' This function is a wrapper for the dtw() function from the dtw package.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param ... Additional parameters for the dtw() function from the dtw package.
#'
#' @return DTW distance
#' @importFrom dtw dtw
#' @export
tsdist_dtw <- function(ts1, ts2, ...) {
    dtw(ts1, ts2, distance.only=TRUE, ...)$distance
}


#' Event synchronization distance test.
#'
#' Quiroga, R. Q., Kreuz, T., & Grassberger, P. (2002). Event synchronization:
#' a simple and fast method to measure synchronicity and time delay patterns.
#' Physical review E, 66(4), 041904.
#'
#' Boers, N., Goswami, B., Rheinwalt, A., Bookhagen, B., Hoskins, B., & Kurths,
#' J. (2019). Complex networks reveal global pattern of extreme-rainfall
#' teleconnections. Nature, 566(7744), 373-377.
#'
#' @param ets1 Event time series 1 (one means an event, or zero otherwise)
#' @param ets2 Event time series 2 (one means an event, or zero otherwise)
#' @param sig_level The significance level to test if correlation is significant.
#' @param tau_max The maximum tau allowed ()
#' @param sig_test Run a significance test. Return 0 if significant or 1 otherwise.
#' @param reps Number of repetitions to construct the confidence interval
#' @param method "quiroga" (default) for the default co-occurrence count and
#'   normalization or "boers" for the co-occurrence count with tau_max and no
#'   normalization.
#'
#' @return distance
#' @export
tsdist_es <- function(ets1, ets2, tau_max = +Inf, method=c("quiroga", "boers"),
                      sig_test=FALSE, reps=100, sig_level=0.01) {
    tts1 = which(ets1 > 0)
    tts2 = which(ets2 > 0)
    t1_num_events = length(tts1)
    t2_num_events = length(tts2)
    t1_length = length(ets1)
    t2_length = length(ets2)
    method = match.arg(method)
    if (sig_test == FALSE & method == "boers")
        stop("The method proposed by Boers et. al (no normalization) can only be
             used in a statistical test (test=TRUE).")
    if (sig_test) {
        sampling_results = sapply(1:reps, function(i){
            t1_random = sample(t1_length, t1_num_events)
            t2_random = sample(t2_length, t2_num_events)
            if (method == "quiroga")
                sample_sim = tssim_event_sync(t1_random, t2_random, tau_max = tau_max,
                                              normalization = "both")
            if (method == "boers") {
                sample_sim = tssim_event_sync(t1_random, t2_random, tau_max = tau_max,
                                              normalization = "none")
            }
            sample_sim
        })
        threshold = quantile(sampling_results, 1 - sig_level)
    }
    if (method == "boers") {
        sim = tssim_event_sync(tts1, tts2, tau_max = tau_max, normalization = "none")
    } else {
        sim = tssim_event_sync(tts1, tts2, tau_max = tau_max, normalization = "both")
    }
    if (sig_test) {
        d = ifelse(sim >= threshold, 0, 1)
    } else {
        d = 1 - sim
    }
    as.numeric(d)
}


#' Event synchronization measure
#'
#' This function is an adapted version of the coocmetric function from
#' the package mmpp. The differences are the introduction of a tau_max
#' limitation factor and the optional normalization.
#'
#' Quiroga, R. Q., Kreuz, T., & Grassberger, P. (2002). Event synchronization:
#' a simple and fast method to measure synchronicity and time delay patterns.
#' Physical review E, 66(4), 041904.
#'
#' Boers, N., Goswami, B., Rheinwalt, A., Bookhagen, B., Hoskins, B., & Kurths,
#' J. (2019). Complex networks reveal global pattern of extreme-rainfall
#' teleconnections. Nature, 566(7744), 373-377.
#'
#' @param tts1 Time indices marking events in time series 1
#' @param tts2 Time indices marking events in time series 2
#' @param tau_max Max tau to be considered
#' @param normalization Forms of normalization after the co-occurrence count.
#'   Possible values "both" (default), "min", and "none". The Default is "both",
#'   the original normalization defined by Quiroga et al: sqrt(N1*N2). This
#'   normalization might be problematic when both time series have very different
#'   number of events. Another possibility is to normalize the count by the "min"
#'   length between both series. The interpretation now takes into account only
#'   the series with less events. For example, considering two series, one with
#'   many events and another with just a single event, the results can be 1
#'   (total sync). The option "none" means no normalization and the method
#'   returns the total count of synchronized events.
#'
#' @importFrom stats na.exclude
#' @return Synchronization-based similarity
tssim_event_sync <- function(tts1, tts2, tau_max = 1, normalization=c("both", "min", "none")) {
    T1 = tts1
    T2 = tts2
    N1 = length(tts1)
    N2 = length(tts2)
    d1 = d2 = 0
    grid = expand.grid(1:N1, 1:N2)
    apply(grid, 1, function(x) {
        k1 = x[1]
        k2 = x[2]
        g = c(T1[k1 + 1] - T1[k1], T1[k1] - T1[k1 -1], T2[k2 + 1] - T2[k2], T2[k2] - T2[k2 - 1])
        g = min(na.exclude(g))/2
        if (g > tau_max)
            g = tau_max
        id1 = T1[k1] - T2[k2]
        id2 = T2[k2] - T1[k1]
        if ((0 < id1) & (id1 < g)) {
            d1 <<- d1 + 1
        }
        else if (id1 == 0) {
            d1 <<- d1 + 1/2
        }
        if ((0 < id2) & (id2 < g)) {
            d2 <<- d2 + 1
        }
        else if (id2 == 0) {
            d2 <<- d2 + 1/2
        }
    })
    val = (d1 + d2)
    normalization = match.arg(normalization)
    if (normalization == "both") {
        val = val/sqrt(N1 * N2)
    } else if(normalization == "min") {
        val = val/min(length(tts1), length(tts2))
    }
    val
}


#' van Rossum distance
#'
#' This function compares the times which the events occur e.g., time indices
#' where the time series values are different than zero. Note that the intensity
#' does not matter but if there is an event or not. This function also performs
#' a statistical test using a shuffling approach to test significance. This
#' implementation uses the fmetric function from the mmpp package.
#'
#' @param ets1 Event time series 1 (one means an event, or zero otherwise)
#' @param ets2 Event time series 2 (one means an event, or zero otherwise)
#' @param tau Parameter for filtering function (See fmetric function from mmpp
#'   package.)
#' @param sig_test Run a statistical test. Return 0 if significant or 1 otherwise.
#' @param reps Number of repetitions to construct the confidence interval
#' @param sig_level The significance level to test if correlation is significant.
#'
#' @return distance
#' @importFrom mmpp fmetric
#' @export
tsdist_vr <- function(ets1, ets2, tau = 1, sig_test=FALSE,
                           reps=100, sig_level=0.01) {
    tts1 = which(ets1 > 0)
    tts2 = which(ets2 > 0)
    t1_num_events = length(tts1)
    t2_num_events = length(tts2)
    t1_length = length(ets1)
    t2_length = length(ets2)
    if (sig_test) {
        sampling_results = sapply(1:reps, function(i){
            t1_random = sample(t1_length, t1_num_events)
            t2_random = sample(t2_length, t2_num_events)
            fmetric(t1_random, t2_random, measure = "dist", tau = tau)
        })
        threshold = quantile(sampling_results, sig_level)
    }
    d = fmetric(tts1, tts2, measure = "dist", tau = tau)
    if (is.na(d))
        d = 1
    if (sig_test) {
        if (is.na(d)) {
            d = 1
        } else if (d < threshold) {
            d = 0
        } else {
            d = 1
        }
    }
    d
}

