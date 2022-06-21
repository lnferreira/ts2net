#' Construct an epsilon-network from a distance matrix.
#'
#' @param D Distance matrix
#' @param eps the threshold value to be considered a link. Only values lower
#'     or equal to epsilon become 1.
#' @param treat_NA_as A numeric value, usually 1, that represent NA values in the
#'     distance matrix
#' @param directed Boolean, directed or undirected (default) network.
#' @param weighted Boolean, TRUE will create a weighted network
#' @param invert_dist_as_weight Boolean, if weighted == TRUE, then the weights
#'     become 1 - distance. This is the default behavior since most network
#'     measures interpret higher weights as stronger connection.
#' @param add_col_rownames Boolean. If TRUE (default), it uses the column and row
#'     names from dist matrix as node labels.
#'
#' @return a igraph network
#' @export
net_enn <- function(D, eps, treat_NA_as=1, directed=FALSE, weighted=FALSE,
                    invert_dist_as_weight = TRUE, add_col_rownames=TRUE) {
    nas = is.na(D)
    if (length(which(nas)) > 0)
        D[nas] = treat_NA_as
    n = matrix(0, nrow(D), ncol(D))
    if (weighted) {
        if (invert_dist_as_weight) {
            if(any(D > 1))
                stop("When invert_dist_as_weight is TRUE, the edge weight is 1 - d. In this case,
                     all values in the distance matrix D should be in the interval [0,1]. ")
            n[D <= eps] = 1 - D[D <= eps]
        } else {
            n[D <= eps] = D[D <= eps]
        }
    } else {
        n[D <= eps] = 1
    }
    if (add_col_rownames){
        colnames(n) = colnames(D)
        rownames(n) = rownames(D)
    }
    net_weighted = NULL
    if (weighted)
        net_weighted = TRUE
    graph.adjacency(n, mode=ifelse(directed, "directed", "undirected"),
                    weighted = net_weighted, diag=FALSE)
}


#' Construct an approximated epsilon neighbor network (faster, but
#' approximated) from a distance matrix. Some actual nearest neighbors
#' may be omitted.
#'
#' @param D Distance matrix
#' @param eps (Integer) k nearest-nearest neighbors where each time series
#' will be connected to
#' @param ... Other parameters to [dbscan::frNN()] function from dbscan package.
#'
#' @importFrom dbscan frNN
#' @return Approximated epsilon nearest-neighbor network
#' @export
net_enn_approx <- function(D, eps, ...) {
    link_list = frNN(as.dist(D), eps = eps, ...)$id
    names(link_list) = 1:length(link_list)
    net = graph_from_adj_list(link_list, mode="all", duplicate = FALSE)
    V(net)$name = colnames(D)
    simplify(net)
}

#' Creates a weighted network.
#'
#' A link is created for each pair of nodes, except if the distance is
#' maximum (1). In network science, stronger links are commonly represented
#' by high values. For this reason, the link weights returned are 1 - D.
#'
#' @param invert_dist_as_weight Boolean, if weighted == TRUE, then the weights
#'     become 1 - distance. This is the default behavior since most network
#'     measures interpret higher weights as stronger connection.
#' @param D Distance matrix. All values must be between [0,1].
#'
#' @return Fully connected network
#' @export
net_weighted <- function(D, invert_dist_as_weight=TRUE) {
    net_enn(D = D, eps = +Inf, weighted = TRUE,
            invert_dist_as_weight = invert_dist_as_weight)
}


#' Construct a knn-network from a distance matrix.
#'
#' @param D Distance matrix
#' @param k (Integer) k nearest-nearest neighbors where each time series
#' will be connected to
#' @param num_cores (Integer) Number of cores to use.
#'
#' @return k nearest-neighbor network
#' @export
net_knn <- function(D, k, num_cores=1) {
    ddim = dim(D)
    D = D + diag(Inf, nrow = ddim[1], ncol = ddim[2])
    A = mclapply(1:nrow(D), function(i){
        x = array(0, ddim[2])
        x[order(D[i, ])[1:k]] = 1
        x
    }, mc.cores = num_cores)
    A = do.call(rbind, A)
    A = A + t(A)
    colnames(A) = colnames(D)
    rownames(A) = rownames(D)
    net = graph.adjacency(A, mode="undirected", diag = FALSE)
    simplify(net)
}


#' Construct an approximated knn-network (faster, but approximated) from
#' a distance matrix.
#'
#' @param D Distance matrix
#' @param k (Integer) k nearest-nearest neighbors where each time series
#' will be connected to
#' @param ... Other parameters to [dbscan::kNN()] function from dbscan package.
#'
#' @return Approximated k nearest-neighbor network
#' @importFrom dbscan kNN
#' @importFrom stats as.dist
#' @export
net_knn_approx <- function(D, k, ...) {
    link_list = kNN(as.dist(D), k = k, ...)$id
    link_list = lapply(1:nrow(link_list), function(i) unname(link_list[i,]))
    names(link_list) = 1:length(link_list)
    net = graph_from_adj_list(link_list, mode="all", duplicate = FALSE)
    V(net)$name = colnames(D)
    simplify(net)
}


#' Construct a network with significant links.
#'
#' Some time series distance functions in ts2net return 0 when the the two
#' time series are statistically similar or 1 otherwise. This function is
#' a wrapper for the [net_enn()] function that construct networks from a
#' binary distance matrix (0 means statistical similar).
#'
#' @param D Distance matrix
#' @param directed Boolean, directed or undirected (default) network.
#' @param add_col_rownames Boolean. If TRUE (default), it uses the column and row
#'     names from dist matrix as node labels.
#'
#' @return
#' @export
net_significant_links <- function(D, directed=FALSE, add_col_rownames=TRUE) {
    net_enn(D, eps = 0, treat_NA_as = 1, directed = directed,
            weighted = FALSE, add_col_rownames = add_col_rownames)
}
