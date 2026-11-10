SUMMARY = "IPMI handlers for the commands the RD450X BIOS sends to its BMC"
DESCRIPTION = "Accepts the SMBIOS tables and asset data the Supermicro-derived \
BIOS uploads over NetFn 0x30, and answers the self test and ACPI power state \
commands so that the BIOS sees a working BMC."
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

DEPENDS = "boost phosphor-ipmi-host phosphor-logging sdbusplus systemd"

inherit meson pkgconfig obmc-phosphor-ipmiprovider-symlink

SRC_URI = "file://meson.build \
           file://rd450x_oem.cpp"

S = "${UNPACKDIR}"

LIBRARY_NAMES = "librd450xoemcmds.so"
HOSTIPMI_PROVIDER_LIBRARY += "${LIBRARY_NAMES}"

FILES:${PN}:append = " ${libdir}/ipmid-providers/lib*${SOLIBS}"
FILES:${PN}:append = " ${libdir}/host-ipmid/lib*${SOLIBS}"
FILES:${PN}-dev:append = " ${libdir}/ipmid-providers/lib*${SOLIBSDEV}"
