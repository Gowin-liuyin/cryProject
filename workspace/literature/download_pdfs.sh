#!/bin/bash
# 下载候选论文 PDF 到 papers/，校验 %PDF 头与大小
cd /Users/yin/code/cryProject/workspace/literature/papers

dl() {
  local name="$1"; local url="$2"
  curl -sL --max-time 60 -o "$name" "$url"
  local head=$(head -c 4 "$name" 2>/dev/null)
  local size=$(stat -f %z "$name" 2>/dev/null)
  if [ "$head" = "%PDF" ] && [ "$size" -gt 51200 ]; then
    echo "OK  $name  ($size bytes)"
  else
    echo "FAIL $name  head=$head size=$size url=$url"
    rm -f "$name"
  fi
}

dl "Primas_masked_single_trace_2017.pdf"        "https://eprint.iacr.org/2017/594.pdf"
dl "Pessl_single_trace_NTT_2019.pdf"            "https://eprint.iacr.org/2019/795.pdf"
dl "GrootBruinderink_flush_gauss_reload_2016.pdf" "https://eprint.iacr.org/2016/300.pdf"
dl "Hermelink_fault_kyber_2021.pdf"             "https://eprint.iacr.org/2021/1222.pdf"
dl "Xagawa_fault_r3_kem_2021.pdf"               "https://eprint.iacr.org/2021/840.pdf"
dl "Pessl_fault_cca_kem_2021.pdf"               "https://tches.iacr.org/index.php/TCHES/article/download/8787/8387"
dl "Rodriguez_em_kyber_2023.pdf"                "https://eprint.iacr.org/2022/1361.pdf"
dl "Kuo_cpa_lattice_kyber_2023.pdf"             "https://eprint.iacr.org/2023/1781.pdf"
dl "Ji_power_kyber_2023.pdf"                    "https://eprint.iacr.org/2022/1452.pdf"
dl "Azouaoui_leakage_kyber_2022.pdf"            "https://eprint.iacr.org/2022/036.pdf"
dl "Hamburg_k_trace_kyber_2021.pdf"             "https://tches.iacr.org/index.php/TCHES/article/download/9061/8648"
dl "Qin_key_mismatch_2021.pdf"                  "https://eprint.iacr.org/2021/123.pdf"
dl "Guo_multipos_mismatch_2023.pdf"             "https://eprint.iacr.org/2022/983.pdf"
dl "Guo_limited_reuse_mismatch_2024.pdf"        "https://eprint.iacr.org/2024/810.pdf"
dl "Mi_lattice_mismatch_2022.pdf"               "https://eprint.iacr.org/2022/1064.pdf"
dl "Ravi_generic_cca_2020.pdf"                  "https://tches.iacr.org/index.php/TCHES/article/download/8592/8159"
dl "KyberSlash_timing_2024.pdf"                 "https://eprint.iacr.org/2024/1049.pdf"
dl "Magazin_em_dataset_2026.pdf"                "https://eprint.iacr.org/2026/1851.pdf"
dl "Mujdei_poly_mult_2024.pdf"                  "https://dl.acm.org/doi/pdf/10.1145/3569420"
dl "Ravi_survey_2024.pdf"                       "https://dl.acm.org/doi/pdf/10.1145/3603170"
dl "Ravi_threshold_crossing_2022.pdf"           "https://dr.ntu.edu.sg/bitstreams/731258aa-b9bb-49f9-9118-70344cc84f2c/download"
dl "Wang_bitsliced_masked_kyber_2023.pdf"       "https://eprint.iacr.org/2023/1042.pdf"
dl "Jendral_single_trace_masked_2024.pdf"       "https://eprint.iacr.org/2024/715.pdf"
dl "Backlund_masked_shuffled_kyber_2023.pdf"    "https://eprint.iacr.org/2022/1692.pdf"
