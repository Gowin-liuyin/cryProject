dataset=m2-m2-s1-unfixed-main
command: PLATFORM_RTLF_SCRIPT=<rtlf.R> Rscript --vanilla -e set.seed(2026101605);source(...) -i <abs path>/normalized.csv -a 0.01 -o run/determinism/rtlf-abs.json -q
result: JSON identical to results/m2-m2-s1-unfixed-main/rtlf.json except the metadata.timestamp field (fixed seed 2026101605 reproducible)
