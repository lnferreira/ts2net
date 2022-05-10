#' Construct an epsilon-network from a distance matrix.
#'
#' @param D Distance matrix
#' @param epsilon the threshold value to be considered a link. Only values lower
#'     or equal to epsilon become 1.
#' @param treat_NA_as A numeric value, usually 1, that represent NA values in the
#'     distance matrix
#' @param is_dist_symetric Boolean, TRUE (default) if dist is symmetric
#' @param weighted Boolean, TRUE will create a weighted network
#' @param invert_dist_as_weight Boolean, if weighted == TRUE, then the weights
#'     become 1 - distance. This is the default behavior since most network
#'     measures interpret higher weights as stronger connection.
#' @param bipartite Boolean. If TRUE, an bipartite network is created. Default:
#'     FALSE. Check igraph::graph.incidence() for more details.
#' @param bipartite_mode Bipartite network mode. Check: igraph::graph.incidence()
#' @param addColRowNames Boolean. If TRUE (default), it uses the column and row
#'     names from dist matrix as node labels.
#'
#' @return a igraph network
#' @export
net_epsilon_create <- function(D, epsilon, treat_NA_as=1, is_dist_symetric=T,
                               weighted=FALSE, invert_dist_as_weight = TRUE,
                               bipartite=FALSE, bipartite_mode = "out", addColRowNames=TRUE) {
    nas = is.na(D)
    if (length(which(nas)) > 0)
        D[nas] = treat_NA_as
    n = matrix(0, nrow(D), ncol(D))
    if (weighted) {
        if (invert_dist_as_weight) {
            if(any(D > 1))
                stop("When invert_dist_as_weight is TRUE, the edge weight is 1 - d. In this case,
                     all values in the distance matrix D should be in the interval [0,1]. ")
            n[D <= epsilon] = 1 - D[D <= epsilon]
        } else {
            n[D <= epsilon] = D[D <= epsilon]
        }
    } else {
        n[D <= epsilon] = 1
    }
    if (addColRowNames){
        colnames(n) = colnames(D)
        rownames(n) = rownames(D)
    }
    net_weighted = NULL
    if (weighted)
        net_weighted = TRUE
    if (bipartite) {
        net = graph.incidence(n, weighted = net_weighted, directed = !is_dist_symetric,
                              mode = bipartite_mode)
    } else {
        net = graph.adjacency(n, mode=ifelse(is_dist_symetric, "undirected", "directed"),
                              weighted = net_weighted, diag=F)
    }
    net
}

#' Creates a weighted network.
#'
#' A link is created for each pair of nodes, except if the distance is
#' maximum (1). In network science, stronger links are commonly represented
#' by high values. For this reason, the link weights returned are 1 - D.
#'
#' @param D Distance matrix. All values must be between [0,1].
#' @param max_dist_value. The value
#'
#' @return Fully connected network
#' @export
net_weighted <- function(D, invert_dist_as_weight=TRUE) {
    net_epsilon_create(D = D, epsilon = +Inf, weighted = TRUE,
                       invert_dist_as_weight = invert_dist_as_weight)
}


#' Construct a knn-network from a distance matrix.
#'
#' @param D Distance matrix
#' @param k (Integer) k nearest-nearest neighbors where each time seires
#' will be connected to
#' @param num_cores (Integer) Number of cores to use.
#'
#' @return
#' @export
net_knn_create <- function(D, k, num_cores=1) {
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

#' Construct a knn-network (faster, but approximated) from a distance matrix.
#'
#' @param D Distance matrix
#' @param k (Integer) k nearest-nearest neighbors where each time seires
#' will be connected to
#' @param ... Other parameters to kNN() function
#'
#' @return
#' @importFrom dbscan kNN
#' @export
net_knn_create_approx <- function(D, k, ...) {
    link_list = kNN(D, k = k, ...)$id
    link_list = lapply(1:nrow(link_list), function(i) unname(link_list[i,]))
    names(link_list) = 1:length(link_list)
    net = graph_from_adj_list(link_list, mode="all", duplicate = F)
    V(net)$name = colnames(D)
    simplify(net)
}
