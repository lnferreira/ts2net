
# Installing and/or loading required packages
pacman::p_load("ts2net", "ggplot2", "scales")

# Constructing a toy data set (list of numeric arrays)
ds = dataset_sincos_generate(num_sin_series = 10, num_cos_series = 10,
                              ts_length = 100, jitter_amount = 0.25)

# Calculating the distance matrix D using the absolute correlation
# distance
D = ts_dist(tsList = ds, dist_func = tsdist_cor, num_cores = 1)

# Constructing an k-NN network
knn_net = net_knn_create(D, k = 2)

# Constructing an epsilon-NN network
eps_net = net_epsilon_create(D, epsilon = 0.5)

# Constructing an weighted network
w_net = net_weighted(D)

# Plotting the three networks
par(ask = TRUE)
net_layout = layout.fruchterman.reingold(knn_net)
plot(knn_net, layout=net_layout, main="k-NN Network", sub="k = 4")
plot(eps_net, layout=net_layout, main=expression(epsilon ~ "-NN"),
     sub=expression(epsilon ~ " = 0.4"))
plot(w_net, layout=net_layout, edge.width=rescale(E(w_net)$weight, c(0.25, 2)),
     main="Weighted network")
par(ask = FALSE)
