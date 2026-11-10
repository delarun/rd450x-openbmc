FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:rd450x = " file://obmc-console.conf"
