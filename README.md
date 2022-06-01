# ts2net <img src="man/figures/logo.png" align="right" height="139" />

[![R-CMD-check](https://github.com/lnferreira/ts2net/workflows/R-CMD-check/badge.svg)](https://github.com/lnferreira/ts2net/actions)
[![Codecov test coverage](https://codecov.io/gh/lnferreira/ts2net/branch/main/graph/badge.svg?token=KFSXU3IE7C)](https://codecov.io/gh/lnferreira/ts2net)
[![License](https://img.shields.io/github/license/lnferreira/ts2net)](https://github.com/lnferreira/ts2net/blob/main/LICENSE)

```ts2net``` is an R package to transform one or multiple time series into networks. This transformation is useful to model and study complex systems, which are commonly represented by a set of time series extracted from the small parts that compose the system. In this case, the network represents time series by nodes that are linked if their respective time series are similar or associated. Network models can also be used for time series data mining. Single or multiple time series can transformed into a networks and analyzed using network science and graph mining tools.

### Installation

The most stable version can be installed from CRAN:

``` r
install.packages("ts2net")
```

The development version can be installed from GitHub using the function `install_github()` from either `devtools` or `remotes` packages:

``` r
install.packages("remotes") # if `remotes` package is not installed
remotes::install_github("lnferreira/ts2net")
```

### Usage

This package provides two forms of network construction. The first modeling approach consists on transforming a set of time series into a network. This transformation typically involves the distance calculation for every pair of time series, represented by the distance matrix _D_. Then, _D_ is transformed into a network using strategies such as _k_ nearest neighbors, &epsilon; neighborhood, or complete weighted graph. The following example shows how to calculate all pairs of distances (_D_) and construct a _k_ nearest neighbor network (knn) using a toy data set composed by five sines and five cosines series (with noise):

``` r
library(ts2net)
ts_list = dataset_sincos_generate(num_sin_series = 5, num_cos_series = 5, ts_length = 50)
D = ts_dist(ts_list) 
net = net_knn(D = D, k = 2)
```

The second approach consists on transform a single time series into a network. The most straightforward method to perform this transformation consists on breaking the time series into time windows and use the same approach described for multiple time series. Other methods, such as visibility graphs or recurrence networks, can also be used. The following example show how to transform a single time series into a visibility graph:

``` r
ts1 = dataset_sincos_generate(num_sin_series = 1, num_cos_series = 0, ts_length = 50)[[1]]
net_vg = tsnet_vg(ts1)
```

For more details, please check the documentation. LINK

### Reference

Please cite this paper if you used ```ts2net``` in a publication:

```
@article{ts2net,
  title         = "From Time Series to Networks in R with ts2net",
  author        = "Ferreira, Leonardo N",
  month         =  May,
  year          =  2022,
  copyright     = "https://github.com/lnferreira/ts2net/blob/main/LICENSE",
  archivePrefix = "arXiv"
  eprint        = ""
}
```

### License

```ts2net``` is distributed under the [MIT license](LICENSE).

### Bugs

Found an issue :bomb: or a bug :bug: ? Please report it [Here](https://github.com/lnferreira/ts2net/issues). 

### Suggestions

Do you have suggestions of improvements or new features? Please add them [here](https://github.com/lnferreira/ts2net/issues). 

### Contact

Leonardo N. Ferreira  
[leonardoferreira.com](https://www.leonardoferreira.com/)  
ferreira@leonardonascimento.com
