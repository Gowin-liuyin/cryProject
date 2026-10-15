# 本轮命令原件（R05 T15 补缺格，2026-10-16）

约定：全部经 `ssh -o ControlPath=/Users/yin/.ssh/cm-cry-nss.sock nss-marker@10.144.144.5`；
全部远端命令 `taskset -c 0,1,3`（避开 CPU2/CPU6）；显式
`TMPDIR=$ROOT/tmp TMP=$ROOT/tmp TEMP=$ROOT/tmp XDG_CACHE_HOME=$ROOT/cache`，
`ROOT=/home/nss-marker/yhr/Cry/r05-locate-20261016-6039f84e5a09`。未 sudo、未改系统配置、未跑锁频。

## 0. 建根与环境

```sh
NONCE=$(od -An -N6 -tx1 /dev/urandom | tr -d " \n")
mkdir -p "$ROOT"/{m2-disasm,m1-disasm,m2-ctgrind,binsec-m5,tmp,cache}
uname -a; nproc; cat /proc/loadavg; date -Is
```

## 1. 产物身份（与既有合同对摘要）

```sh
sha256sum /home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2/{unfixed,fixed}/measure
# 期望：dd4073ba…（未修 a621b8d） / c48f89a5…（已修 272125f）
sha256sum /home/nss-marker/yhr/Cry/liboqs010-historical-20261015-86131c2/build/\
{historical-clangover,historical-fixed-982c762}/historical/measure
# 期望：bd84ee9c…（未修）/ 1849821e…（982c762 已修）
```

## 2. M2 重加密 × 提前返回

```sh
M2=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/build-ordinary/platform-m2
objdump -d --disassemble=pqcrystals_kyber768_ref_poly_frommsg "$M2/unfixed/measure" > "$ROOT/m2-disasm/unfixed-poly_frommsg.asm"
objdump -d --disassemble=pqcrystals_kyber768_ref_poly_frommsg "$M2/fixed/measure"   > "$ROOT/m2-disasm/fixed-poly_frommsg.asm"
objdump -d "$M2/unfixed/measure" > "$ROOT/m2-disasm/unfixed-full.asm"
objdump -d "$M2/fixed/measure"   > "$ROOT/m2-disasm/fixed-full.asm"
# 指令字节列（去掉地址与符号名）后比对
for v in unfixed fixed; do
  sed -n "/<pqcrystals_kyber768_ref_poly_frommsg>:/,/^$/p" "$ROOT/m2-disasm/$v-poly_frommsg.asm" \
    | grep -E "^ +[0-9a-f]+:" | sed -E "s/^ +[0-9a-f]+:\t([0-9a-f ]+)\t.*/\1/" | tr -s " " \
    > "$ROOT/m2-disasm/$v-poly_frommsg.bytes"
done
cmp -s "$ROOT/m2-disasm/unfixed-poly_frommsg.bytes" "$ROOT/m2-disasm/fixed-poly_frommsg.bytes" && echo IDENTICAL
# 调用点与包含它的函数
grep -n "call.*poly_frommsg" "$ROOT/m2-disasm/unfixed-full.asm"
grep -n "<pqcrystals_kyber768_ref_indcpa_enc>:\|<pqcrystals_kyber768_ref_dec>:" "$ROOT/m2-disasm/unfixed-full.asm"
```

## 3. M1 隐式拒绝（可变时间比较 / 失败路径）

```sh
M1=/home/nss-marker/yhr/Cry/liboqs010-historical-20261015-86131c2/build
objdump -d "$M1/historical-clangover/historical/measure"       > "$ROOT/m1-disasm/clangover-full.asm"
objdump -d "$M1/historical-fixed-982c762/historical/measure"   > "$ROOT/m1-disasm/fixed-full.asm"
# 关注符号：pqcrystals_ml_kem_768_ipd_ref_{verify,cmov,cmov_int16,poly_frommsg,dec}、
#           OQS_KEM_ml_kem_768_ipd_decaps、mlkem_decapsulate
grep -n "<pqcrystals_ml_kem_768_ipd_ref_cmov>:\|<pqcrystals_ml_kem_768_ipd_ref_verify>:\|<pqcrystals_ml_kem_768_ipd_ref_dec>:" "$ROOT/m1-disasm/fixed-full.asm"
# dec 函数体内的 call 链与跳转计数
S=$(grep -n "<pqcrystals_ml_kem_768_ipd_ref_dec>:" "$ROOT/m1-disasm/fixed-full.asm" | cut -d: -f1)
E=$(awk -v s="$S" 'NR>s && /^[0-9a-f]+ </{print NR; exit}' "$ROOT/m1-disasm/fixed-full.asm")
sed -n "${S},${E}p" "$ROOT/m1-disasm/fixed-full.asm" | grep -oE "call +[0-9a-f]+ <[^>]+>"
sed -n "${S},${E}p" "$ROOT/m1-disasm/fixed-full.asm" | grep -cE "\s+j[a-z]+ "
# 有没有跳转以 2b09..2b37（verify 之后到 cmov 调用）为落点
grep -nE "j[a-z]+ +2b(0[9a-f]|[1-2][0-9a-f]|3[0-7]) " "$ROOT/m1-disasm/fixed-full.asm" || echo "(none)"
# 按函数切指令字节并出摘要
#   见 m1-disasm/function-byte-hashes.txt、m1-disasm/*.bytes
```

## 4. M2 秘密标记 Memcheck 探针（补哈希 G/H/J）

```sh
SRC=/home/nss-marker/yhr/Cry/platform-m2kem-20261016-d75a4019/source/vendor
# probe_dec.c 源码见 m2-ctgrind/probe/probe_dec.c
VENDOR_FILES="kem.c indcpa.c poly.c polyvec.c ntt.c reduce.c verify.c cbd.c fips202.c symmetric-shake.c"
for which in unfixed fixed; do
  VD="$SRC/kyber-kyberslash-$which"
  for name in $VENDOR_FILES; do
    clang -O1 -g -DNDEBUG -DKYBER_K=3 -I"$VD/ref" -c "$VD/ref/$name" -o "$ROOT/m2-ctgrind/probe/$which-$name.o"
  done
  clang -O1 -g -DNDEBUG -DKYBER_K=3 -I"$VD/ref" -c "$ROOT/m2-ctgrind/probe/probe_dec.c" -o "$ROOT/m2-ctgrind/probe/probe_dec-$which.o"
  clang -O1 -g -o "$ROOT/m2-ctgrind/probe/probe_$which" \
        "$ROOT/m2-ctgrind/probe/probe_dec-$which.o" "$ROOT"/m2-ctgrind/probe/$which-*.o
  objdump -d --disassemble=pqcrystals_kyber768_ref_dec "$ROOT/m2-ctgrind/probe/probe_$which" > "$ROOT/m2-ctgrind/$which-dec.asm"
done
# 16 次运行：2 变体 × 8 分区（分区累积标记，最后一次覆盖整段 1152 B）
sh "$ROOT/m2-ctgrind/run_sweep.sh"          # 脚本原件见 m2-ctgrind/run_sweep.sh
# 等价单次：
taskset -c 0,1,3 valgrind --error-exitcode=99 --track-origins=yes \
  "$ROOT/m2-ctgrind/probe/probe_unfixed" 8 7
```

## 5. M5 重加密 Binsec `checkct` 尝试

```sh
B=/home/nss-marker/yhr/Cry/platform-m4-binsec-20261016-73f14add5392
BINSEC="$B/runtime/binsec-0.11.3/_opam/bin/binsec"
export PATH="$(dirname "$B/runtime/bin/z3"):$PATH"
# A：强行用 -isa amd64 加载 M4 的 i386 静态 ELF
"$BINSEC" -isa amd64 -sse -checkct -smt-solver z3 -sse-script "$ROOT/binsec-m5/probe-empty-script.cfg" \
  -sse-depth 200 -sse-timeout 30 -smt-timeout 5 -checkct-features control-flow,memory-access \
  "$B/build-formal/platform_m4_formal_ct"
# B / B2 / B3 / B4：M4 内核上的配置敏感性实验（配置原件同目录）
"$BINSEC" -sse -checkct -smt-solver z3 -sse-script "$ROOT/binsec-m5/<cfg>" -sse-depth 10000 \
  -sse-timeout 60 -smt-timeout 5 -checkct-features control-flow,memory-access \
  -checkct-stats-file "$ROOT/binsec-m5/<name>.checkct.toml" "$B/build-formal/platform_m4_formal_vulnerable"
# C：默认 loader 加载 M5 的 x86-64 ELF
"$BINSEC" -sse -checkct -smt-solver z3 -sse-script "$ROOT/binsec-m5/C-m5-default-isa.cfg" \
  -sse-depth 50 -sse-timeout 30 -smt-timeout 5 -checkct-features control-flow,memory-access \
  /home/nss-marker/yhr/Cry/platform-m5-20261016-30efdf66eb26/build-v2-ordinary/platform_m5_poison
# 32 位退路探测
printf 'int main(void){return 0;}\n' > "$ROOT/tmp/probe32.c"; clang -m32 -o "$ROOT/tmp/probe32" "$ROOT/tmp/probe32.c"
```

## 6. 归档与回传

```sh
tar czf "$ROOT/../r05-locate-20261016-6039f84e5a09.tar.gz" -C "$(dirname "$ROOT")" "$(basename "$ROOT")"
sha256sum "$ROOT/../r05-locate-20261016-6039f84e5a09.tar.gz"
# 本机
scp nss-marker@10.144.144.5:/home/nss-marker/yhr/Cry/r05-locate-20261016-6039f84e5a09.tar.gz \
    docs/evidence/r05-locate-20261016/
tar xzf r05-locate-20261016-6039f84e5a09.tar.gz && mv r05-locate-20261016-6039f84e5a09 remote-tree
```

## 7. 本轮未执行

- 未重新采集计时数据、未跑锁频、未动频率/隔离/nice 配置。
- 未重跑 M5 的三模式 Valgrind（只解归档复核 `logs-v2/*` 的 `ERROR SUMMARY` 与退出码）。
- 未修改任何既有证据目录；未 `git add/commit/push`。
