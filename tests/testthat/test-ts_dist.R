test_that("test distance parts", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    part1 = tsdist_parts_parallel(ts_list, num_part = 1, num_total_parts = 3)
    part2 = tsdist_parts_parallel(ts_list, num_part = 2, num_total_parts = 3)
    part3 = tsdist_parts_parallel(ts_list, num_part = 3, num_total_parts = 3)
    parts = list(part1, part2, part3)
    D1 = tsdist_parts_merge(parts, 10)
    D2 = ts_dist(ts_list)
    expect_true(all(D1 == D2))
})


test_that("test distance parts from files", {
    ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
    temp_dir = tempdir()
    temp_dir_tss = file.path(temp_dir, 'tss')
    temp_dir_dists = file.path(temp_dir, 'dists')
    dir.create(temp_dir_tss, showWarnings = F)
    dir.create(temp_dir_dists, showWarnings = F)
    ts_files_tss = sprintf("%s/%02d.RDS", temp_dir_tss, 1:10)
    ts_files_dists = sprintf("%s/%02d.RDS", temp_dir_dists, 1:3)
    for (i in 1:10)
        saveRDS(ts_list[[i]], ts_files_tss[[i]])
    for (i in 1:3) {
        dist_part_from_file = tsdist_dir_parallel(input_dir = temp_dir_tss, num_part = i, num_total_parts = 3)
        dist_part_no_file = tsdist_parts_parallel(ts_list, num_part = i, num_total_parts = 3)
        expect_true(all.equal(dist_part_from_file, dist_part_no_file))
        saveRDS(dist_part_from_file, ts_files_dists[i])
    }
    D1 = tsdist_file_parts_merge(dir_path = temp_dir_dists, num_elements = 10)
    D2 = ts_dist(ts_list)
    expect_true(all(D1 == D2))
    unlink(temp_dir, recursive = T)
})
