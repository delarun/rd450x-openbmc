# 32 MB flash on an ARM926: drop features the board does not need.
IMAGE_FEATURES:remove:rd450x = "obmc-telemetry obmc-tpm obmc-dmtf-pmci obmc-dmtf-spdm obmc-user-mgmt-ldap obmc-remote-logging-mgmt"

OBMC_IMAGE_EXTRA_INSTALL:append:rd450x = " rd450x-uart-routing phosphor-ipmi-ipmb dbus-sensors"

# The writable filesystem is only 2 MB: a single core dump (bmcweb: 2.7 MB)
# fills it and blocks the crashed service from restarting while it is being
# written. Keep only the journal entry for a crash.
rd450x_no_coredump_storage() {
    install -d ${IMAGE_ROOTFS}${sysconfdir}/systemd/coredump.conf.d
    printf '[Coredump]\nStorage=none\nProcessSizeMax=0\n' \
        > ${IMAGE_ROOTFS}${sysconfdir}/systemd/coredump.conf.d/rd450x.conf
}
ROOTFS_POSTPROCESS_COMMAND:append:rd450x = " rd450x_no_coredump_storage"
