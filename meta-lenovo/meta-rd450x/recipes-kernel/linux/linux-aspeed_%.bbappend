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

# I2C bus 4 is shared with the Intel ME, which is a master too. Collisions
# make the controller report abnormal conditions and recover about twenty
# times a second; each one was logged at error level, and journald then took
# more than half of the BMC's CPU. The transfers are retried and the ME
# readings are fine, so log these two conditions at debug level.
do_patch:append:rd450x() {
    sed -i -e 's/dev_err(bus->dev, "bus in unknown state. irq_status: 0x%x\\n",/dev_dbg(bus->dev, "bus in unknown state. irq_status: 0x%x\\n",/' \
        -e '/^\t\tdev_err(bus->dev,$/{N;s/dev_err(bus->dev,\n\t\t\t"irq handled != irq/dev_dbg(bus->dev,\n\t\t\t"irq handled != irq/}' \
        ${S}/drivers/i2c/busses/i2c-aspeed.c
    ! grep -B1 'irq handled != irq' ${S}/drivers/i2c/busses/i2c-aspeed.c | grep -q dev_err
    ! grep 'bus in unknown state' ${S}/drivers/i2c/busses/i2c-aspeed.c | grep -q dev_err
}
