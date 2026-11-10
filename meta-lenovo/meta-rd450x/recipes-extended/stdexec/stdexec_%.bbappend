# stop_token.hpp emits the "yield" instruction for every 32-bit ARM target,
# but ARMv5 (the ARM926 in the AST2400) does not have it and the assembler
# rejects it. Only use it from ARMv7 on; older cores simply spin.
do_install:append() {
    f=${D}${includedir}/stdexec/stop_token.hpp
    grep -q 'defined(__aarch64__) || defined(__arm__)' $f
    sed -i 's/defined(__aarch64__) || defined(__arm__)/defined(__aarch64__) || (defined(__arm__) \&\& __ARM_ARCH >= 7)/' $f
}
