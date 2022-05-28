

#' Construct the visibility graph from a time series
#'
#' TODO: limit distance
#' TODO: weights
#'
#' @param x Array. Time series
#' @param method String. Construction method: "nvg" (default) for
#'   Natural visibility graph, "hvg" horizontal visibility graph.
#' @param num_cores Number of cores (default = 1).
#' @param limit Positive integer. The maximum temporal distance (indexes)
#'   allowed in the visibility. This parameter limits the max visibility.
#'
#' @return visibility graph
#' @export
tsnet_vg <- function(x, method=c("nvg", "hvg"), limit=+Inf, num_cores=1) {
    id_combs = combn(length(x), 2, simplify = F)
    method = match.arg(method)
    links = unlist(mclapply(id_combs, \(ids){
        linked = TRUE
        if (abs(diff(ids))!=1) {
            switch(method,
                   nvg={
                        for (i in seq(ids[1]+1, ids[2]-1)) {
                            if (x[i] >= x[ids[2]] + ((x[ids[1]]-x[ids[2]])*(ids[2]-i)/(ids[2]-ids[1]))) {
                                linked = FALSE
                                break
                            }
                        }
                    },
                    hvg = {
                        for (i in seq(ids[1]+1, ids[2]-1)) {
                            if (x[i] >= x[ids[1]] || x[i] >= x[ids[2]]) {
                                linked = FALSE
                                break
                            }
                        }
                    })
        }
        linked
    }, mc.cores = num_cores))
    links = do.call(rbind, id_combs[links])
    graph.data.frame(links, directed = F)
}


#' Construct the recurrence network from a time series.
#'
#' This function constructs the recurrence matrix of the time
#' series using the function `rqa()` from \pkg{nonlinearTseries}
#' package.
#'
#' @param x Array. Time series
#' @param radius Maximum distance between two phase-space
#'   points to be considered a recurrence.
#' @param embedding.dim Integer denoting the dimension in which
#'   we shall embed the time.series. If missing, the embedding
#'   dimensions is estimated using `estimateEmbeddingDim()` from
#'   \pkg{nonlinearTseries}. The constructed igraph network has
#'   the estimated dimension (and other info) as a parameter.
#'   For example: net$embedding_dim
#' @param time.lag Integer denoting the number of time steps that
#'   will be use to construct the Takens' vectors.
#' @param do.plot Boolean. Show recurrence plot (default = FALSE)
 #' @param ... Other parameters to `rqa()` from \pkg{nonlinearTseries}
#'
#' @return recurrence network
#' @importFrom nonlinearTseries rqa estimateEmbeddingDim
#' @export
tsnet_rn <- function(x, radius, embedding.dim, time.lag=1, do.plot = FALSE, ...) {
    if (missing(embedding.dim))
        embedding.dim = estimateEmbeddingDim(time.series = x,
                                             time.lag = time.lag,
                                             do.plot = FALSE)
    rm = rqa(time.series = x, radius = radius, embedding.dim = embedding.dim ,
             do.plot=do.plot, ...)$recurrence.matrix
    net = graph.adjacency(as.matrix(rm), mode = "undirected")
    net$embedding_dim = embedding.dim
    net$time_lag = time.lag
    net$radius = radius
    simplify(net)
}
