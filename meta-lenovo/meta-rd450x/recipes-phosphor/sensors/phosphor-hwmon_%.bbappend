FILESEXTRAPATHS:prepend:rd450x := "${THISDIR}/${PN}:"

RD450X_HWMON = " \
    ahb/apb/pwm-tacho-controller@1e786000.conf \
    ahb/apb/bus@1e78a000/i2c@40/temperature-sensor@4c.conf \
    iio-hwmon.conf \
    "
RD450X_HWMON_ENVS = "obmc/hwmon/{0}"
SYSTEMD_ENVIRONMENT_FILE:${PN}:append:rd450x = " ${@compose_list(d, 'RD450X_HWMON_ENVS', 'RD450X_HWMON')}"
