FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:rd450x = " file://ipmb-channels.json"

do_install:append:rd450x() {
    install -m 0644 -D ${UNPACKDIR}/ipmb-channels.json \
        ${D}${datadir}/ipmbbridge/ipmb-channels.json
}
