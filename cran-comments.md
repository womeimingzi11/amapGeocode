## Test environments
* local R installation, R 4.1.0 devel
* ubuntu 16.04 (on travis-ci), R 4.0.2
* win-builder (devel)

## R CMD check results

0 errors | 0 warnings | 1 note
> unable to verify current time

* An upgrade:

  1. Replace the class of result from `tibble` to `data.table`
  
  2. Remove some package dependencies
  
  3. Some code improvements
