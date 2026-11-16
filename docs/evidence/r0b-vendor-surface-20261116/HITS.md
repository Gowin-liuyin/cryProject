# R0b vendor 防护链泄露面扫描（r0b-vendor-surface-20261116）

本表只登记固定清单内文件的逐行正则命中，供人工复核；**不做自动定性**，
不表示命中即泄露，也不修改 vendor 任何文件。

- 日期：2026-11-16
- 配置：`docs/evidence/r0b-vendor-surface-20261116/scan-config.json`
- 规则：`abort\s*\(\|assert\s*\(\|fprintf\s*\(\|printf\s*\(\|perror\s*\(\|errno\|exit\s*\(`
- 清单：5 棵 vendor 树 / 22 个文件（不扫全树）

## 1. 扫描范围与文件摘要

| 文件 | 行数 | 命中行数 | 文件 SHA-256 |
|---|---:|---:|---|
| `vendor/liboqs-0.10.0/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/poly.c` | 360 | 0 | `ba90afe5bbf862ef8c8fed967542871152446199c4d0983cd4cf4d39bc77ee57` |
| `vendor/liboqs-0.10.0/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/indcpa.c` | 331 | 0 | `345481d276b228c29859f35e8e11c2f9240bbdad7a6678fa38d30406f1c9f54a` |
| `vendor/liboqs-0.10.0/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/kem.c` | 169 | 0 | `fef2dc668e54772f42c5ed3151a1728a78a5a63f4d2551836f50cd96bebd0e9c` |
| `vendor/liboqs-0.10.0/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/verify.c` | 47 | 0 | `6a3b66b46aa76102d780ba5ca94e1a2e6041feecb801f190310e9b10c18a705d` |
| `vendor/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/poly.c` | 360 | 0 | `e8d8d92a474fe609bc8300dce73734e3b0789a6e9afdfd9fe569bd9f63034e0c` |
| `vendor/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/indcpa.c` | 331 | 0 | `345481d276b228c29859f35e8e11c2f9240bbdad7a6678fa38d30406f1c9f54a` |
| `vendor/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/kem.c` | 169 | 0 | `fef2dc668e54772f42c5ed3151a1728a78a5a63f4d2551836f50cd96bebd0e9c` |
| `vendor/liboqs-0.10.0-982c762/src/kem/ml_kem/pqcrystals-kyber-standard_ml-kem-768-ipd_ref/verify.c` | 65 | 0 | `06f4843fdc7827ef9bb02a8eccc8256024818bd0e5512f21a4c2c06379d4dd09` |
| `vendor/kyber-kyberslash-unfixed/ref/poly.c` | 343 | 0 | `f23c985b837e406b273d2770ce614692db6d7bac08d1c1d506c26bc00956c49a` |
| `vendor/kyber-kyberslash-unfixed/ref/indcpa.c` | 329 | 0 | `00ab5c0e5c36fa0b7a6cc2dcf5bcc503150a2f0059f628db66c60023b7d06fb7` |
| `vendor/kyber-kyberslash-unfixed/ref/kem.c` | 127 | 0 | `9fef5424622a0b69f336c797c6e6b07b749ffd3123840a746ed4a14168d0ec53` |
| `vendor/kyber-kyberslash-unfixed/ref/verify.c` | 57 | 0 | `461b7d1ea898ffc4dde772cc7a98228c542d4fa7eef98178974b2d3143fa7b29` |
| `vendor/kyber-kyberslash-unfixed/ref/fips202.c` | 774 | 0 | `5df8461d9dc938d6a2960d72b0d331adbfa9beed4116f9d295eef6af238632ee` |
| `vendor/kyber-kyberslash-fixed/ref/poly.c` | 359 | 0 | `9c8ff1a3e597b24a703939550b8cfd0e8b18a934293c50babadaed02c6c37d30` |
| `vendor/kyber-kyberslash-fixed/ref/indcpa.c` | 329 | 0 | `00ab5c0e5c36fa0b7a6cc2dcf5bcc503150a2f0059f628db66c60023b7d06fb7` |
| `vendor/kyber-kyberslash-fixed/ref/kem.c` | 127 | 0 | `9fef5424622a0b69f336c797c6e6b07b749ffd3123840a746ed4a14168d0ec53` |
| `vendor/kyber-kyberslash-fixed/ref/verify.c` | 57 | 0 | `461b7d1ea898ffc4dde772cc7a98228c542d4fa7eef98178974b2d3143fa7b29` |
| `vendor/kyber-kyberslash-fixed/ref/fips202.c` | 774 | 0 | `5df8461d9dc938d6a2960d72b0d331adbfa9beed4116f9d295eef6af238632ee` |
| `vendor/mlkem-native/mlkem/src/verify.h` | 447 | 0 | `76fd0af32577f9118d1ea90a66ff77e18cdf99d08dcf1c9df137833041e8492f` |
| `vendor/mlkem-native/mlkem/src/verify.c` | 20 | 0 | `f8f89f1b8c8e5811ce134c0d90fb7828027336afeed231dc3ccb7ee6b73b9335` |
| `vendor/mlkem-native/mlkem/src/kem.c` | 474 | 0 | `3922156826521429eb250ccb3d54d7beacce14adce26bb3be6d1ef7864342dd3` |
| `vendor/mlkem-native/mlkem/src/fips202/fips202.c` | 249 | 0 | `fb0654c0b33c45c929fdb2af2287807a7b8f312ac7f3baa3ddfaef0c030ef0b2` |

合计命中行 **0** 行。

## 2. 逐行命中

（无命中）

