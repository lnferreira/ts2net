# ts2net <img src="man/figures/logo.png" align="right" height="139" />

[![R-CMD-check](https://github.com/lnferreira/ts2net/workflows/R-CMD-check/badge.svg)](https://github.com/lnferreira/ts2net/actions)
[![Codecov test coverage](https://codecov.io/gh/lnferreira/ts2net/branch/main/graph/badge.svg?token=KFSXU3IE7C)](https://app.codecov.io/gh/lnferreira/ts2net/)
[![CRAN/METACRAN](https://img.shields.io/cran/v/ts2net?color=blue)](https://cran.r-project.org/package=ts2net)
[![License: MIT](https://img.shields.io/badge/License-MIT-brightgreen.svg)](https://github.com/lnferreira/ts2net/blob/main/LICENSE.md)

```ts2net``` is an R package to transform one or multiple time series into networks. This transformation is useful to model and study complex systems, which are commonly represented by a set of time series extracted from the small parts that compose the system. In this case, the network represents time series by nodes that are linked if their respective time series are similar or associated. Network models can also be used for time series data mining. Single or multiple time series can be transformed into networks and analyzed using network science and graph mining tools.

**THIS IS A BETA VERSION - Please report bugs [HERE](https://github.com/lnferreira/ts2net/issues)**

## Reference

For details about this package, check out the paper:

> ***[Leonardo N. Ferreira, From Time Series to Networks in R with the ts2net Package (2024)](https://doi.org/10.1007/s41109-024-00642-2)***

**Please cite this paper if you used ```ts2net``` in a publication:**

``` 
@article{ferreira24,
	author = {Ferreira, Leonardo N.},
	date = {2024/07/08},
	doi = {10.1007/s41109-024-00642-2},
	isbn = {2364-8228},
	journal = {Applied Network Science},
	number = {1},
	pages = {32},
	title = {From time series to networks in R with the ts2net package},
	url = {https://doi.org/10.1007/s41109-024-00642-2},
	volume = {9},
	year = {2024}
}
```

## Installation

From CRAN:

``` r
install.packages("ts2net")
```

The development version can be installed from GitHub using the function `install_github()` from either `devtools` or `remotes` packages:

``` r
install.packages("remotes") # if `remotes` package is not installed
remotes::install_github("lnferreira/ts2net")
```

## Usage

The `ts2net` package provides two modelling approaches: one or a set of time series as a network.

### A set of time series as a network

The first modeling approach consists of transforming a set of time series into a network. This transformation typically involves the distance calculation for every pair of time series, represented by the distance matrix _D_. Then, _D_ is transformed into a network using strategies such as _k_ nearest neighbors, &epsilon; nearest neighbors, or complete weighted graphs. The following example shows how to calculate all pairs of distances (_D_) and construct a &epsilon; nearest neighbor network (&epsilon;-NN) using a data set (available with `ts2net`) composed of the temperature variations in 27 cities in the US:

``` r
library(ts2net)
# Calculating the distance matrix
D = ts_dist(us_cities_temperature_list, dist_func = tsdist_dtw)
# Finding the epsilon that corresponds to 30% of the shortest distances
eps = dist_percentile(D, percentile = 0.3)
# Constructing the network
net = net_enn(D, eps)
```

![Multiple time series as networks](inst/figs/fig07_black.png#gh-dark-mode-only)![Multiple time series as networks](inst/figs/fig07.png#gh-light-mode-only)
**Fig. 1:** Transforming time series into a network using ts2net. (a) The historical temperature of 27 cities in the US. (b) The distance matrix _D_ (normalized DTW) for the data set. (c) The &epsilon;-NN network was constructed using 30% of the shortest distances. Node colors represent communities.

Functions to calculate the distance matrix:

- `ts_dist()`: Calculates all pairs of distances and returns a distance matrix. Runs in parallel.
- `ts_dist_part()`: Calculates pairs of distances in part of data set. This function is useful to run in parallel as jobs.
- `ts_dist_part_file()`: Similar to `ts_dist_part()`, but read time series from files. It should be preferred when memory consumption is a concern, e.g., huge data set or very long time series.

Distance functions available:

- `tsdist_cor()`: Absolute, positive or negative correlation. Significance test available.
- `tsdist_ccf()`: Absolute, positive, or negative cross-correlation.
- `tsdist_dtw()`: Dynamic time warping (DTW).
- `tsdist_nmi()`: Normalized mutual information.
- `tsdist_voi()`: Variation of information.
- `tsdist_mic()`: Maximal information coefficient (MIC).
- `tsdist_es()`: Events synchronization. Significance test available.
- `tsdist_vr()`: Van Rossum. Significance test available.

Methods to transform **multiple** time series into a network:

- `net_knn()`: _k_-NN network
- `net_knn_approx()`: _k_-NN network. Faster, but may omit some nearest neighbors.
- `net_enn()`: &epsilon;-NN
- `net_enn_approx()`: &epsilon;-NN. Faster, but may omit some nearest neighbors.
- `net_weighted()`: Full weighted network
- `net_significant_links()`: Creates a network from a binary distance matrix (0 means significant links).

### A single time series as a network

The second approach consists of transforming a single time series into a network. The following example shows how to transform a time series of monthly atmospheric concentration of carbon dioxide into a proximity network, a visibility graph, a recurrence network, and a transition network:


The second approach consists of transforming a single time series into a network. The following example shows how to transform the time series of monthly atmospheric concentration of carbon dioxide (available by default in R) into a proximity network, a visibility graph, a recurrence network, and a transition network:

``` r
co2_ts = as.numeric(co2)
# 1. Proximity (correlation) network
co2_windows = ts_to_windows(co2_ts, width = 12, by = 1)
D = ts_dist(co2_windows, cor_type = "+")
net_p = net_enn(D, eps = 0.25)
# 2. Visibility graph
net_vg = tsnet_vg(co2_ts)
# 3. Recurrence network
net_rn = tsnet_rn(co2_ts, radius = 5)
# 4. Transition (quantile) network
net_qn = tsnet_qn(co2_ts, breaks = 100)
```

![Single time series as networks](inst/figs/fig08_black.png#gh-dark-mode-only)![Single time series as networks](inst/figs/fig08.png#gh-light-mode-only)
**Fig. 2:** (a) CO<sub>2</sub> concentration time series. (b) Proximity network with time window 12 and one-value step. (c) Natural visibility graph. (d) Recurrence network (&epsilon; = 5). (e) Transition (quantile) network (100 equally-spaced bins). Node colors represent temporal order (yellow to purple), except in the transition network where colors represent the sequence of lower (yellow) to higher (purple) bins.).

Methods to transform **one** time series into a network:

- `ts_to_windows()`: Extracts time windows that can be used to construct networks using the same approach used for multiple ones (Fig 1.).
- `tsnet_vg()`: Natural and horizontal visibility graphs.
- `tsnet_rn()`: Recurrence networks.
- `tsnet_qn()`: Transition (quantile) networks.

## License

```ts2net``` is distributed under the [MIT license](https://github.com/lnferreira/ts2net/blob/main/LICENSE.md).

## Bugs

Found an issue :bomb: or a bug :bug: ? Please report it [Here](https://github.com/lnferreira/ts2net/issues). 

## Suggestions

Do you have suggestions of improvements or new features? Please add them [here](https://github.com/lnferreira/ts2net/issues). 

## Contact

Leonardo N. Ferreira  
[leonardoferreira.com](https://www.leonardoferreira.com/)  
ferreira@leonardonascimento.com
