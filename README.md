# OpenBMC for the Lenovo ThinkServer RD450X

An OpenBMC machine layer (`meta-lenovo/meta-rd450x`) for the BMC of the Lenovo
RD450X mainboard: ASPEED AST2400 (ARM926), 32 MB SPI NOR, 256 MB RAM. It
replaces the stock AMI MegaRAC firmware.

**Status: works on one board, use at your own risk.** Everything here was
worked out on a single RD450X by reverse-engineering the stock firmware and
probing the live board. Flashing a BMC can leave the board without one; read
the recovery section before you start.

## What works

| Area | State |
|---|---|
| Boot, network over NC-SI (shared host NIC), web UI, Redfish, SSH | Works |
| Host power: on/off/reset, front-panel buttons (forwarded in software) | Works |
| Fans: 5 tachs, 6 PWM channels, closed-loop control with fail-safe | Works |
| Temperatures: CPU0/CPU1 and PCH through the Intel ME, board sensor | Works |
| Voltages: 12 V, 5 V, 3.3 V, 5 V aux, 3.3 V standby | Works |
| Remote KVM (video + USB keyboard) | Works |
| Serial over LAN (host COM1) | Works |
| Host IPMI over KCS (port 0xCA2) | Works, device ID is a placeholder |
| Mainboard FRU inventory, LEDs | Works |
| Virtual media (ISO over USB) | Works (about 0.9 MB/s) |
| BIOS flashing from the BMC (`rd450x-bios`, BIOS region only) | Works (read, write and restore verified) |
| BIOS update from the web UI / Redfish (plain ROM file) | Upload path verified up to the power check; the write itself is the `rd450x-bios` one |
| CPU, DIMM and BIOS version inventory (SMBIOS pushed from the host OS) | Works |
| PSU telemetry | Not implemented |
| Dedicated IPMI LAN port | Untested |

## Things worth knowing about this board

- The Intel ME sits on I2C bus 4 (address 0x16) and is the only source of CPU
  temperature: Node Manager command 0x4B returns the margin to Tjmax per CPU.
  `dbus-sensors` gets a small patch for it.
- The board temperature chip is an ADM1032-class device at 0x4c on bus 0.
- `SYS_FAN1` has no tach signal; its PWM is left at 100 %.
- The `dbus-sensors` daemons that read hwmon files stop polling on this
  ARM926/kernel 6.18 combination (lost io_uring wake-ups), so fans, voltages
  and the board chip are served by `phosphor-hwmon` instead.
- UART1/UART2 (the host's COM1/COM2) must be enabled in the device tree or
  their clocks are gated and the host's serial ports are dead.
- The flash layout differs from the stock OpenBMC 32 MB layout (kernel 4.5 MB,
  rofs 25 MB, rwfs 2 MB) to make room for KVM.
- Comments in the device tree and recipes mark what was verified on hardware
  and what is still an assumption.

## Building

The layer is developed against OpenBMC commit
`14d5a4165f04dd7606fb28585a315dbcf81a3dbc` (2026-11-09, kernel 6.18).

```sh
git clone https://github.com/openbmc/openbmc.git
git -C openbmc checkout 14d5a4165f04dd7606fb28585a315dbcf81a3dbc
ln -s ../meta-lenovo openbmc/meta-lenovo

docker build -t rd450x-openbmc-build build-env
export RD450X_BUILD_DIR=/path/with/100GB/free
mkdir -p "$RD450X_BUILD_DIR"

build-env/run.sh 'TEMPLATECONF=meta-lenovo/meta-rd450x/conf/templates/default \
    . ./oe-init-build-env $BUILD && bitbake obmc-phosphor-image'
```

The images land in `$RD450X_BUILD_DIR/tmp/deploy/images/rd450x/`:
`obmc-phosphor-image-rd450x.static.mtd` is the full 32 MB flash image,
`image-kernel` and `image-rofs` are used for updates.

The build is memory-hungry: on a 32 GB machine it was killed by the OOM
killer at 12 parallel tasks and completed at `BB_NUMBER_THREADS = "6"`,
`PARALLEL_MAKE = "-j 8"` (set in `conf/local.conf`).

## Flashing and recovery

There is no recovery path over UART on the AST2400. What worked here:

- **First flash and recovery, from the running host OS.** The AST2400's VGA
  P2A bridge is open on this board, so ASPEED `socflash` can read and write the
  BMC flash from Linux on the host, even when the BMC is dead:

  ```sh
  ./socflash_x64 -b stock-backup.bin                 # read; keep this file
  ./socflash_x64 if=obmc-phosphor-image-rd450x.static.mtd option=f
  ```

  The BMC is halted while `socflash` runs and reboots afterwards. Do not reboot
  or power off the host while the BMC is in an unknown state: `socflash` only
  works from a booted host.

- **Routine updates, over the network.** Copy `image-kernel` and `image-rofs`
  to `/run/initramfs/` on the BMC and reboot it. This keeps U-Boot and the
  settings, but only works while the flash layout is unchanged.

Take a backup of the stock firmware first and keep it. After a full flash the
U-Boot environment is empty; set the MAC addresses again with `fw_setenv
ethaddr` / `eth1addr`, otherwise the BMC comes up with a random MAC.

The default login is the OpenBMC development default (`root` / `0penBmc`).
Change it.

## Flashing the host BIOS from the BMC

The 16 MB host flash (Intel flash descriptor layout) sits behind a mux that
GPIOH6 controls. `rd450x-bios` on the BMC takes the flash while the host is
powered off, and only then:

```sh
rd450x-bios info                 # chip and descriptor regions
rd450x-bios backup /tmp/full.bin # whole flash, including the ME region
rd450x-bios verify /tmp/new.rom  # compare the BIOS region
rd450x-bios write  /tmp/new.rom  # write the BIOS region (about 2 minutes)
```

- Only the BIOS region (0x400000-0xffffff) is written. The descriptor and the
  ME region are never touched, and an image with a different descriptor is
  refused.
- Writing replaces the NVRAM too: BIOS settings and UEFI boot entries come
  from the image. Writing a `backup` file back restores them.
- Copy the backup off the BMC: `/tmp` is a RAM disk.
- The Intel ME keeps its data in the same flash. Taking the flash away while
  the ME is still starting leaves it in recovery mode until the next ME reset,
  so the script waits for a clean ME self test first and resets the ME after a
  write.
- The mux line is put back to "host" by the kernel on every BMC start, so an
  interrupted run cannot leave the host without its flash. During testing the
  BMC was reset by its watchdog once in the middle of a read; the cause was
  not found and it did not happen again in further runs.

### From the web UI

Operations -> Firmware accepts a plain 16 MB BIOS image (no tarball or
MANIFEST needed): an upload that carries an Intel flash descriptor is treated
as a host image and written with `rd450x-bios write`. Power the host off
first; with the host on the update fails and nothing is touched. The reason
is in the BMC journal (`journalctl -u 'obmc-flash-host-bios@*'`).

## CPU and memory inventory

The BIOS does not hand its SMBIOS tables to the BMC, so a helper on the host
OS does: `host-tools/rd450x-smbios-push` reads the tables the kernel exports
(what `dmidecode` shows) and writes them to the BMC through the local IPMI
interface (`ipmitool`, KCS; no network access or BMC password). `smbios-mdr`
on the BMC turns them into the processor, DIMM and BIOS version inventory
shown in the web UI and Redfish. The BMC keeps the last tables it received.

```sh
install -m 0755 host-tools/rd450x-smbios-push /usr/local/sbin/
install -m 0644 host-tools/rd450x-smbios-push.service /etc/systemd/system/
systemctl enable --now rd450x-smbios-push.service   # resend on every boot
```

## Layout

- `meta-lenovo/meta-rd450x/` — the machine layer: machine config, device tree,
  kernel config fragments, sensor and fan-control configuration, patches.
- `build-env/` — Dockerfile and wrapper for a reproducible build container.
- `host-tools/` — helper for the host OS that sends the SMBIOS tables to the BMC.

## License

The recipes and configuration in this repository are provided under the
Apache-2.0 license, the same as OpenBMC. The device tree source is
GPL-2.0-or-later, like the kernel sources it is built with.
