# CPU and DIMM inventory from the host's SMBIOS tables. The BIOS of this
# board does not send them itself; a helper on the host OS pushes the table
# through the IPMI blob interface over KCS (see host-tools/).
PACKAGECONFIG:append:rd450x = " smbios-ipmi-blob"
