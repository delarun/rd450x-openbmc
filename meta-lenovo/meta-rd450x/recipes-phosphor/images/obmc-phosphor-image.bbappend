# 32 MB flash on an ARM926: drop features the board does not need.
IMAGE_FEATURES:remove:rd450x = "obmc-telemetry obmc-tpm obmc-dmtf-pmci obmc-dmtf-spdm obmc-user-mgmt-ldap obmc-remote-logging-mgmt"

OBMC_IMAGE_EXTRA_INSTALL:append:rd450x = " rd450x-uart-routing rd450x-bios phosphor-ipmi-ipmb dbus-sensors"

# The writable filesystem is only 2 MB: a single core dump (bmcweb: 2.7 MB)
# fills it and blocks the crashed service from restarting while it is being
# written. Keep only the journal entry for a crash.
rd450x_no_coredump_storage() {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/coredump.conf.d
    printf '[Coredump]\nStorage=none\nProcessSizeMax=0\n' \
        > ${IMAGE_ROOTFS}${sysconfdir}/systemd/coredump.conf.d/rd450x.conf
}
ROOTFS_POSTPROCESS_COMMAND:append:rd450x = " rd450x_no_coredump_storage"

# Virtual media: bmcweb buffers at most ~128 KB of image data coming from the
# browser. With the kernel's default request size (64 KB+) and queue depth two
# replies already overflow that buffer and the session dies. Small requests
# and a short queue keep the outstanding data below the limit.
rd450x_nbd_udev_rule() {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d
    printf '%s\n' 'ACTION=="add|change", KERNEL=="nbd[0-9]*", ATTR{queue/max_sectors_kb}="16", ATTR{queue/nr_requests}="4", ATTR{queue/read_ahead_kb}="16"' \
        > ${IMAGE_ROOTFS}${sysconfdir}/udev/rules.d/90-rd450x-nbd.rules
}
ROOTFS_POSTPROCESS_COMMAND:append:rd450x = " rd450x_nbd_udev_rule"
