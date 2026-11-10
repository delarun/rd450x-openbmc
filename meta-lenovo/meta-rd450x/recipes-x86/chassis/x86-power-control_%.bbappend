FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:rd450x = " file://power-config-host0.json"

do_install:append:rd450x() {
    install -d ${D}${datadir}/${PN}
    install -m 0644 ${UNPACKDIR}/power-config-host0.json ${D}${datadir}/${PN}
}

# The front-panel buttons are not coupled to the host in hardware under this
# kernel (see the device tree); let the daemon forward them.
EXTRA_OEMESON:append:rd450x = " -Dbutton-passthrough=enabled"
