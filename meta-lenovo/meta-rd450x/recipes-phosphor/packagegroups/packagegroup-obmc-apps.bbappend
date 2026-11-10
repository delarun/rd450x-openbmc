# phosphor-fan-monitor is not configured for this board (fans are handled by
# phosphor-hwmon + phosphor-pid-control) and the flash is nearly full.
RDEPENDS:${PN}-fan-control:remove:rd450x = "phosphor-fan-monitor"
