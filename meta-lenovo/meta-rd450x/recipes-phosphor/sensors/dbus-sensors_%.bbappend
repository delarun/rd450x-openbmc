# Only the IPMB sensor daemon is used (CPU and PCH temperatures from the
# Intel ME). Fans, voltages and the board temperature chip are served by
# phosphor-hwmon: the dbus-sensors daemons that read hwmon files rely on
# io_uring, and on this ARM926 kernel their event loop loses wake-ups and
# stops polling.
PACKAGECONFIG:rd450x = "ipmbsensor"

# CPU temperatures come from the Intel ME with a Node Manager command the
# stock ipmbsensor does not know.
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"
SRC_URI:append:rd450x = " file://0001-ipmb-add-Node-Manager-CPU-temperature-class.patch"

# dbus-sensors builds asio to run entirely on io_uring (epoll disabled). On
# this ARM926 kernel such event loops lose wake-ups and stop polling. With
# epoll left enabled, ipmbsensor (no file I/O) uses plain epoll and timerfd
# and does not touch io_uring at all - verified on the board.
do_configure:prepend:rd450x() {
    sed -i "/'-DBOOST_ASIO_DISABLE_EPOLL',/d" ${S}/meson.build
}
