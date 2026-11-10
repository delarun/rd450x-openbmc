FILESEXTRAPATHS:prepend:rd450x := "${THISDIR}/${PN}:"

SRC_URI:append:rd450x = " file://config.json"

# Drive the fans to the fail-safe duty when the controller is not running.
PACKAGECONFIG:append:rd450x = " offline-failsafe"

FILES:${PN}:append:rd450x = " ${datadir}/swampd/config.json"

# Zones, curves and sensor time-outs: a temperature or tach reading that
# stops updating puts its zone at 100 %.
do_install:append:rd450x() {
    install -d ${D}${datadir}/swampd
    install -m 0644 ${UNPACKDIR}/config.json ${D}${datadir}/swampd/config.json
}
