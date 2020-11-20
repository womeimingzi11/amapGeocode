## Test environments
* local R installation, R 4.0.3
* ubuntu 16.04 (on travis-ci), R 4.0.2
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note

* An upgrade:

  Replace `lapply` and `mapply` by `parLapply` and `clusterMap` to add parallel operation support
