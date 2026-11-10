#!/bin/sh
# The host owns UART1 over LPC. Cross-connect it with the BMC's UART3
# (ttyS2), as the stock firmware does for serial-over-LAN.
set -e
for d in /sys/bus/platform/drivers/aspeed-uart-routing/*.uart-routing; do
    [ -d "$d" ] || continue
    echo -n uart1 > "$d/uart3"
    echo -n uart3 > "$d/uart1"
    exit 0
done
echo "aspeed-uart-routing device not found" >&2
exit 1
