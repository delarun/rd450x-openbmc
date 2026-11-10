SUMMARY = "Route the host serial port (UART1) to the BMC's UART3 for SOL"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit allarch systemd

SRC_URI = "file://rd450x-uart-routing.sh \
           file://rd450x-uart-routing.service"

S = "${UNPACKDIR}"

SYSTEMD_SERVICE:${PN} = "rd450x-uart-routing.service"

do_install() {
    install -d ${D}${libexecdir}/${PN}
    install -m 0755 ${UNPACKDIR}/rd450x-uart-routing.sh ${D}${libexecdir}/${PN}/
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${UNPACKDIR}/rd450x-uart-routing.service ${D}${systemd_system_unitdir}/
}
