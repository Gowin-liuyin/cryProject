sh -c 
    getconf CHAR_BIT
    getconf INT_MAX
    cat build/release/generated/RelWithDebInfo/configuration.txt
    sha256sum SOURCE_EXPORT.sha256 build/release/audit build/release/reference/baseline build/release/reference/benchmark build/release/reference/libmlkem.a build/release/hardened/benchmark build/release/deployable/benchmark
    file build/release/audit build/release/reference/benchmark
    readelf -W -l build/release/reference/benchmark
    ldd build/release/reference/benchmark
    gcc -std=c11 -DMLK_CONFIG_FILE=\"baseline_config.h\" -Iinclude -Ivendor/mlkem-native/mlkem -dM -E src/kernel.c | LC_ALL=C sort
    nm build/release/reference/libmlkem.a

