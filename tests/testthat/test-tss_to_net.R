
test_that("Create knn network", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    D = ts_dist(ts_list)
    net = net_knn(D = D, k = 2)
    expect_equal(vcount(net), 10)
})


test_that("Create enn network", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    D = ts_dist(ts_list)
    net = net_enn(D = D, eps = 0.5)
    expect_equal(vcount(net), 10)
})


test_that("Create approximated knn network", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    D = ts_dist(ts_list)
    net = net_knn_approx(D = D, k = 2)
    expect_equal(vcount(net), 10)
})


test_that("Create approximated enn network", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    D = ts_dist(ts_list)
    net = net_enn_approx(D = D, eps = 0.5)
    expect_equal(vcount(net), 10)
})


test_that("Create weighted full network", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    D = ts_dist(ts_list)
    net1 = net_weighted(D)
    W1 = get.adjacency(net1, attr = "weight", sparse = F)
    expect_equal(vcount(net1), 10)
    expect_equal(graph.density(net1), 1)
    expect_true(all(1 - D - diag(10) == W1))
    net2 = net_weighted(D, invert_dist_as_weight = F)
    W2 = get.adjacency(net2, attr = "weight", sparse = F)
    expect_equal(vcount(net2), 10)
    expect_equal(graph.density(net2), 1)
    expect_true(all(D == W2))
})


