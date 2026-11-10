SUMMARY = "Read and write the host BIOS flash of the RD450X from the BMC"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit allarch

SRC_URI = "file://rd450x-bios \
           file://rd450x-bios-uploaded \
           file://71-rd450x-bios-mux.rules"

S = "${UNPACKDIR}"

do_install() {
    install -d ${D}${sbindir}
    install -m 0755 ${UNPACKDIR}/rd450x-bios ${D}${sbindir}/
    install -d ${D}${libexecdir}/${PN}
    install -m 0755 ${UNPACKDIR}/rd450x-bios-uploaded ${D}${libexecdir}/${PN}/
    install -d ${D}${nonarch_base_libdir}/udev/rules.d
    install -m 0644 ${UNPACKDIR}/71-rd450x-bios-mux.rules \
        ${D}${nonarch_base_libdir}/udev/rules.d/
}

FILES:${PN} += "${nonarch_base_libdir}/udev/rules.d"
