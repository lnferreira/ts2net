test_that("Test distance parts", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    part1 = ts_dist_part(ts_list, num_part = 1, num_total_parts = 3)
    part2 = ts_dist_part(ts_list, num_part = 2, num_total_parts = 3)
    part3 = ts_dist_part(ts_list, num_part = 3, num_total_parts = 3)
    parts = list(part1, part2, part3)
    D1 = dist_parts_merge(parts, 10)
    D2 = ts_dist(ts_list)
    expect_true(all(D1 == D2))
})


test_that("Test distance parts from files", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    temp_dir = tempdir()
    temp_dir_tss = file.path(temp_dir, 'tss')
    temp_dir_dists = file.path(temp_dir, 'dists')
    dir.create(temp_dir_tss, showWarnings = FALSE)
    dir.create(temp_dir_dists, showWarnings = FALSE)
    ts_files_tss = sprintf("%s/%02d.RDS", temp_dir_tss, 1:10)
    ts_files_dists = sprintf("%s/%02d.RDS", temp_dir_dists, 1:3)
    for (i in 1:10)
        saveRDS(ts_list[[i]], ts_files_tss[[i]])
    for (i in 1:3) {
        dist_part_from_file = ts_dist_part_file(input_dir = temp_dir_tss, num_part = i, num_total_parts = 3)
        dist_part_no_file = ts_dist_part(ts_list, num_part = i, num_total_parts = 3)
        expect_true(all.equal(dist_part_from_file, dist_part_no_file))
        saveRDS(dist_part_from_file, ts_files_dists[i])
    }
    D1 = dist_file_parts_merge(dir_path = temp_dir_dists, num_elements = 10)
    D2 = ts_dist(ts_list)
    expect_true(all(D1 == D2))
    unlink(temp_dir, recursive = TRUE)
})


test_that("Correlation distances", {
    ts_list = dataset_sincos_generate(num_sin_series = 2, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin1 = ts_list[[1]]
    ts_sin2 = ts_list[[2]]
    ts_cos1 = ts_list[[3]]
    expect_equal(round(tsdist_cor(ts_sin1, ts_sin1), 10), 0)
    expect_gt(tsdist_cor(ts_sin1, ts_cos1), 0.5)
    expect_equal(round(tsdist_cor(ts_sin1, -ts_sin1, cor_type = "abs"), 10), 0)
    expect_equal(round(tsdist_cor(ts_sin1, -ts_sin1, cor_type = "+"), 10), 1)
    expect_equal(round(tsdist_cor(ts_sin1, -ts_sin1, cor_type = "-"), 10), 0)
    expect_equal(tsdist_cor(ts_sin1, ts_sin2, cor_type = "+", sig_test = TRUE), 0)
    expect_equal(tsdist_cor(ts_sin1, ts_sin2, cor_type = "+", sig_test = TRUE, sig_level=1), 0)
})


test_that("Cross-correlation distances", {
    ts_list = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin = ts_list[[1]]
    ts_cos = ts_list[[2]]
    expect_equal(round(tsdist_ccf(ts_sin, ts_sin), 10), 0)
    expect_lt(tsdist_ccf(ts_sin, ts_cos), 0.5)
    expect_equal(round(tsdist_ccf(ts_sin, -ts_sin, cor_type = "abs"), 10), 0)
    expect_lt(tsdist_ccf(ts_sin, -ts_sin, cor_type = "+"), 0.5)
    expect_equal(round(tsdist_ccf(ts_sin, -ts_sin, cor_type = "-"), 10), 0)
})


test_that("Variation of information distance", {
    ts_list = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin = ts_list[[1]]
    ts_cos = ts_list[[2]]
    expect_equal(round(tsdist_voi(ts_sin, ts_sin), 10), 0)
    expect_gt(tsdist_voi(ts_sin, ts_cos, nbins = 10), 0.1)
    expect_gt(tsdist_voi(ts_sin, ts_cos, nbins = "sturges"), 0.1)
    expect_gt(tsdist_voi(ts_sin, ts_cos, nbins = "freedman-diaconis"), 0.1)
    expect_gt(tsdist_voi(ts_sin, ts_cos, nbins = "scott"), 0.1)
    expect_gt(tsdist_voi(ts_sin, ts_cos, method = "sg"), 0.1)
})


test_that("Normalized mutual information distance", {
    ts_list = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin = ts_list[[1]]
    ts_cos = ts_list[[2]]
    expect_equal(round(tsdist_nmi(ts_sin, ts_sin), 10), 0)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, nbins = 10), 0.1)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, nbins = "sturges"), 0.1)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, nbins = "freedman-diaconis"), 0.1)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, nbins = "scott"), 0.1)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, method = "sg"), 0.1)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, normalization = "min"), 0.1)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, normalization = "max"), 0.1)
    expect_gt(tsdist_nmi(ts_sin, ts_cos, normalization = "sqrt"), 0.1)
    expect_lt(tsdist_nmi(ts_sin, ts_cos, normalization = "min"), 1)
    expect_lt(tsdist_nmi(ts_sin, ts_cos, normalization = "max"), 1)
    expect_lt(tsdist_nmi(ts_sin, ts_cos, normalization = "sqrt"), 1)
})


test_that("Maximal information coefficient (MIC) distance", {
    ts_list = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin = ts_list[[1]]
    ts_cos = ts_list[[2]]
    expect_equal(round(tsdist_mic(ts_sin, ts_sin), 10), 0)
    expect_gt(tsdist_mic(ts_sin, ts_cos), 0.1)
    expect_lt(tsdist_mic(ts_sin, ts_cos), 1)
})


test_that("Dynamic Time Warping (DTW) distance", {
    ts_list = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin = ts_list[[1]]
    ts_cos = ts_list[[2]]
    expect_equal(round(tsdist_dtw(ts_sin, ts_sin), 10), 0)
    expect_gt(tsdist_dtw(ts_sin, ts_cos), 0.1)
    expect_gt(tsdist_dtw(ts_sin, ts_cos, window.type="sakoechiba", window.size=3), 0.1)
})


test_that("Event synchronization distance", {
    ts_list = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin = ts_list[[1]]
    ts_cos = ts_list[[2]]
    ets_sin = events_from_ts(ts_sin, 3, "highest")
    ets_cos = events_from_ts(ts_cos, 3, "highest")
    expect_equal(round(tsdist_es(ets_sin, ets_sin), 10), 0)
    expect_gt(tsdist_es(ets_sin, ets_cos, tau_max = 1), 0.1)
    expect_equal(tsdist_es(ets_sin, ets_sin, sig_test = TRUE, reps=10), 0)
    expect_equal(tsdist_es(ets_sin, ets_cos, tau=0, method = "boers", sig_test=TRUE), 1)
})


test_that("van Rossum distance", {
    ts_list = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 1,
                                      ts_length = 50, jitter_amount = 0.15)
    ts_sin = ts_list[[1]]
    ts_cos = ts_list[[2]]
    ets_sin = events_from_ts(ts_sin, 3, "highest")
    ets_cos = events_from_ts(ts_cos, 3, "highest")
    expect_equal(round(tsdist_vr(ets_sin, ets_sin), 10), 0)
    expect_gt(tsdist_vr(ets_sin, ets_cos), 0.1)
    expect_equal(tsdist_vr(ets_sin, ets_cos, tau=0), 1)
    expect_equal(tsdist_vr(ets_sin, ets_cos, sig_test = TRUE, reps = 30), 1)
    expect_equal(tsdist_vr(ets_sin, ets_sin, sig_test = TRUE, reps = 40), 0)
})
