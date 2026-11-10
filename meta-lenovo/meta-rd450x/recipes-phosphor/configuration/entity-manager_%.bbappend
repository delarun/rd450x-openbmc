FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI:append:rd450x = " \
    file://rd450x-baseboard.json \
    file://rd450x-mainboard-fru.json \
    file://blacklist.json \
"

# GPIO presence is not used on this board.
PACKAGECONFIG:remove:rd450x = "gpio-presence"

# Do not reuse the configuration cached by an earlier firmware: the cache is
# keyed on os-release, which does not change between local builds, so an
# updated board file was ignored after a firmware update.
EXTRA_OEMESON:append:rd450x = " -Dnew-device-detection=false"

do_install:append:rd450x() {
    # 32 MB flash: ship only this board's configuration
    find ${D}${datadir}/${BPN}/configurations -mindepth 1 -maxdepth 1 \
        -exec rm -rf {} +
    install -m 0644 ${UNPACKDIR}/rd450x-baseboard.json \
        ${UNPACKDIR}/rd450x-mainboard-fru.json \
        ${D}${datadir}/${BPN}/configurations/
    # fru-device probes every address of every bus it is allowed on. Only
    # bus 8 (mainboard FRU EEPROM at 0x57) is known to carry a FRU; keep it
    # off the buses with the voltage regulators, the ME and the backplanes.
    install -m 0644 ${UNPACKDIR}/blacklist.json ${D}${datadir}/${BPN}/blacklist.json
}
