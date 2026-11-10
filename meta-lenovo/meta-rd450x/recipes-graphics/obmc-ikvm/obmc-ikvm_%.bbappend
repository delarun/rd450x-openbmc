# create_usbhid.sh only recognises AST2500 and later. The AST2400 has the
# same virtual hub at the same address (1e6a0000.usb-vhub), so treat it
# like an AST2500.
do_install:append:rd450x() {
    sed -i 's/\*aspeed,ast2500\*)/*aspeed,ast2400* | *aspeed,ast2500*)/' \
        ${D}${bindir}/create_usbhid.sh
    grep -q 'aspeed,ast2400' ${D}${bindir}/create_usbhid.sh
}
