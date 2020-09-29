## Test environments
* local R installation, R 4.0.2
* ubuntu 16.04 (on travis-ci), R 4.0.2
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note
> unable to verify current time

* An upgrade:
  1. add `getAdmin` and `extractAdmin` functions
  2. add `convertCoord` and `extractConvertCoord` functions
  3. revise the DESCRIPTION to match the request of CRAN
  4. add batch process ability
