

#' Construct the visibility graph from a time series
#'
#' @param x Array. Time series
#' @param method String. Construction method: "nvg" (default) for
#'   Natural visibility graph, "hvg" horizontal visibility graph.
#' @param num_cores Number of cores (default = 1).
#'
#' @return visibility graph
#' @export
tsnet_vg <- function(x, method=c("nvg", "hvg"), num_cores=1) {
    id_combs = combn(length(x), 2, simplify = F)
    method = match.arg(method)
    links = unlist(mclapply(id_combs, \(ids){
        switch(method,
               nvg={
                   linked = TRUE
                   if (abs(diff(ids))!=1) {
                        for (i in seq(ids[1]+1, ids[2]-1)) {
                            if (x[i] >= x[ids[2]] + ((x[ids[1]]-x[ids[2]])*(ids[2]-i)/(ids[2]-ids[1]))) {
                                linked = FALSE
                                break
                            }
                        }
                    }
                    linked
                },
                hvg = {
                    linked = TRUE
                    if (abs(diff(ids))!=1) {
                        for (i in seq(ids[1]+1, ids[2]-1)) {
                            if (x[i] >= x[ids[1]] || x[i] >= x[ids[2]]) {
                                linked = FALSE
                                break
                            }
                        }
                    }
                    linked
                })
    }, mc.cores = num_cores))
    links = do.call(rbind, id_combs[links])
    graph.data.frame(links, directed = F)
}
