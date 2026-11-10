FILESEXTRAPATHS:prepend := "${THISDIR}/linux-aspeed:"

SRC_URI:append:rd450x = " \
    file://aspeed-bmc-lenovo-rd450x.dts \
    file://rd450x-size.cfg \
    file://rd450x-hw.cfg \
    file://rd450x-kvm.cfg \
"

# The board is not upstream: drop its device tree into the kernel tree.
do_patch:append:rd450x() {
    cp ${UNPACKDIR}/aspeed-bmc-lenovo-rd450x.dts \
        ${S}/arch/arm/boot/dts/aspeed/
}
