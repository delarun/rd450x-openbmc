FILESEXTRAPATHS:prepend:rd450x := "${THISDIR}/${PN}:"

SRC_URI:append:rd450x = " file://led-group-config.json"

do_install:append:rd450x() {
    install -m 0644 ${UNPACKDIR}/led-group-config.json ${D}${datadir}/phosphor-led-manager/
}
