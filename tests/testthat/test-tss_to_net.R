
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

