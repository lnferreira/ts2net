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
#' @importFrom compiler cmpfun
#' @export
ts_dist <- function(tsList, measureFunc=tsdist_cor, isSymetric=TRUE,
                          error_value=NaN, warn_error=TRUE, num_cores=1, ...) {
    measureFuncCompiled <- cmpfun(measureFunc)
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
#' @param tsList List of time series.
#' @param num_part Numeric positive between 1 and the total number of parts
#'     (num_total_parts). This value corresponds to the part (chunck) of the
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
#' @param measureFunc Function to be applied to all combinations
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
tsdist_parts_parallel <- function(tsList, num_part, num_total_parts, combinations, measureFunc=tsdist_cor,
                                isSymetric=TRUE, error_value=NaN, warn_error=TRUE, simplify=TRUE,
                                num_cores=1, ...) {
    measureFuncCompiled <- cmpfun(measureFunc)
    tsListLength = length(tsList)
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
            measureFuncCompiled(tsList[[ids[1]]], tsList[[ids[2]]], ...)
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
#'     (num_total_parts). This value corresponds to the part (chunck) of the
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
#' @param simplify Boolean. If FALSE (default), returns a list of one (
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
tsdist_dir_parallel <- function(input_dir, num_part, num_total_parts, combinations, measureFunc=tsdist_cor,
                              isSymetric=TRUE, error_value=NaN, warn_error=TRUE, simplify=FALSE,
                              num_cores=1, ...) {
    measureFuncCompiled <- cmpfun(measureFunc)
    list_files = list.files(path = input_dir, full.names = T, pattern = "RDS")
    tsListLength = length(list_files)
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



#' Merge parts of distances stored in data frames.
#'
#' The functions tsdist_dir_parallel and tsdist_parts_parallel calculate part of
#' the distance matrix D. This function merges these files and construct
#' a distance matrix D.
#'
#' @param list_dfs A list of data frames. Each data frame should have three
#'   columns i,j, and dist.
#' @param num_elements The number of time series in the data set. The number of elements
#'   defines the number of rows ans columns in the distance matrix D.
#'
#' @return Distance matrix D
#' @export
tsdist_parts_merge <- function(list_dfs, num_elements) {
    D = matrix(1, num_elements, num_elements)
    for (df_d in list_dfs) {
        D[as.matrix(df_d[,c("i", "j")])] = df_d$dist
    }
    D
}


#' Merge parts of distances stored in files.
#'
#' The functions tsdist_dir_parallel and tsdist_parts_parallel calculate part of
#' the distance matrix D. The results of the multiple calls of these functions are
#' normally stored in RDS or csv files. This function merges these files and construct
#' a distance matrix D.
#'
#' @param list_files A list of files with distances.
#' @param dir_path If list_files was not passed, than this function uses this parameter
#'   to read the files in this directory.
#' @param num_elements The number of time series in the data set. The number of elements
#'   defines the number of rows ans columns in the distance matrix D.
#' @param file_type The extension of the files where the distances are stored. It can be
#'   "RDS" (default) or "csv". The RDS files should be data frames composed by three
#'   columns i,j, and dist. This format is preferred because it is a compact file. The other
#'   option is a "csv" also containing the i,j, and dist columns.
#'
#' @return Distance matrix D
#' @export
tsdist_file_parts_merge <- function(list_files, dir_path, num_elements, file_type="RDS") {
    if (missing(list_files))
        files = list.files(dir_path, pattern = file_type, include.dirs = F, full.names = T)
    D = matrix(1, num_elements, num_elements)
    for (file in files) {
        if (file_type == "RDS") {
            df_d = readRDS(file)
        } else {
            df_d = read.csv(file, row.names = F)
        }
        if (class(df_d) == "list")
            df_d = do.call(rbind, df_d)
        D[as.matrix(df_d[,c("i", "j")])] = df_d$dist
    }
    D
}


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


#' Absolute, positive, or negative correlation distance.
#'
#' Perfect positive returns zero and one means no  or negative correlations. The
#' opposite occurs if positive_cor==F.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param cor_type String. "abs" (default), "+", or "-". "abs" considers the
#'   correlation absolute value. "+" only positive correlations and "-" only
#'   negative correlations.
#'
#' @return Real value [0,1] where 0 means perfect positive (or negative
#' if positive_cor==F) correlation and 1 no positive (or negative
#' if positive_cor==F) correlation.
#' @export
tsdist_cor <- function(ts1, ts2, cor_type="abs") {
    r = cor(ts1, ts2)
    if (cor_type == "+") {
        d_cor = 1 - pmax(0, r)
    } else if (cor_type == "-") {
        d_cor = 1 - pmax(0, r * -1)
    } else {
        d_cor = 1 - abs(r)
    }
    d_cor
}


#' Absolute, positive, or negative test correlation distance.
#'
#' This function is similar to tsdist_cor(), but also performs a significance
#' test to check if the absolute, positive, or negative correlation distance
#' is significant. See cor.test() for more details. This function returns only
#' zero (if significant) or one.
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param cor_type String. "abs" (default), "+", or "-". "abs" considers the
#'   correlation absolute value. "+" only positive correlations and "-" only
#'   negative correlations.
#' @param sig_level The significance level to test if correlation is significant.
#'   See cor.test().
#'
#' @return Zero iff significant, or one otherwise.
#' @export
tsdist_cor_test <- function(ts1, ts2, cor_type="abs", sig_level=0.01) {
    r_test = cor.test(ts1,ts2)
    r = as.numeric(r_test$estimate)
    d_cor = 1
    if (!is.na(corr$p.value) && corr$p.value < sig_level) {
        if ((cor_type == "+" & r > 0) | (cor_type == "-" & r < 0))
            d_cor = 0
        if (cor_type != "+" & cor_type != "-")
            d_cor = 0
    }
    d_cor
}


#' Cross-correlation distance
#'
#' Minimum correlation distance considering a +- lag máxium (lag_max)
#'
#' @param ts1 Array. Time series 1
#' @param ts2 Array. Time series 2
#' @param type String. "correlation" or "covariance" to be used (type) in the ccf function.
#' @param cor_type String. "abs" (default), "+", or "-". "abs" considers the
#'   correlation absolute value. "+" only positve correlations and "-" only
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
    dtw(ts1,ts2, ...)$distance
}
