FILESEXTRAPATHS:prepend:rd450x := "${THISDIR}/${PN}:"

# Host BIOS update from the web UI (Operations -> Firmware): the uploaded
# image is handed to rd450x-bios, which writes the BIOS region only and
# refuses to run while the host is powered on.
PACKAGECONFIG:append:rd450x = " flash_bios"

SRC_URI:append:rd450x = " \
    file://0001-bmc-accept-raw-host-flash-images.patch \
    file://obmc-flash-host-bios@.service \
    "

do_install:append:rd450x() {
    install -m 0644 ${UNPACKDIR}/obmc-flash-host-bios@.service \
        ${D}${systemd_system_unitdir}/obmc-flash-host-bios@.service
}

RDEPENDS:${PN}-updater:append:rd450x = " rd450x-bios"
