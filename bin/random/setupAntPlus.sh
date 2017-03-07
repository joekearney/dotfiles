#!/bin/bash

set -e -u -o pipefail

if [[ "$EUID" != "0" ]]; then
  echo "You must be root"
  exit 1
fi

if [[ "$(uname)" == "Darwin" ]]; then
  echo "This only works on Linux, not MacOS"
fi

function writeUdev() {
  local UDEV_DIR=/etc/udev
  local UDEV_RULES_FILE=${UDEV_DIR}/ant-rules.d

  mkdir -p ${UDEV_DIR}
  cat <<EOF > ${UDEV_RULES_FILE}
# It will give consistent names for the Ant device.
# e.g., /dev/ttyANT0 (for first Ant device), /dev/ttyANT1 etc.

# Ant devbox
  SUBSYSTEM=="tty" ACTION=="add" \
  ATTRS{product}=="Dynastream ANT Development Board Rev 3.0" \
  SYMLINK+="ttyANT%n"

# Ant little dev board
  SUBSYSTEM=="tty" ACTION=="add" \
  ATTRS{idProduct}=="1006" \
  ATTRS{idVendor}=="0fcf" \
  SYMLINK+="ttyANT%n"

# Ant stick
  SUBSYSTEM=="tty" ACTION=="add" \
  ATTRS{idProduct}=="1004" \
  ATTRS{idVendor}=="0fcf" \
  SYMLINK+="ttyANT%n"

# Ant stick, usbm driver
  SUBSYSTEM=="usb" ACTION=="add" \
  ATTRS{idProduct}=="1009" \
  ATTRS{idVendor}=="0fcf" \
  RUN+="/sbin/modprobe option" \
  RUN+="/bin/sh -c 'echo 0fcf 1009 > /sys/bus/usb-serial/drivers/option1/new_id'"

# Ant stick, usbm
  SUBSYSTEM=="tty" ACTION=="add" \
  ATTRS{idProduct}=="1009" \
  ATTRS{idVendor}=="0fcf" \
  SYMLINK+="ttyANT%n"

# Ant stick, usb2 driver
  SUBSYSTEM=="usb" ACTION=="add" \
  ATTRS{idProduct}=="1008" \
  ATTRS{idVendor}=="0fcf" \
  RUN+="/sbin/modprobe option" \
  RUN+="/bin/sh -c 'echo 0fcf 1008 > /sys/bus/usb-serial/drivers/option1/new_id'"

# Ant stick, usb2
  SUBSYSTEM=="tty" ACTION=="add" \
  ATTRS{idProduct}=="1008" \
  ATTRS{idVendor}=="0fcf" \
  SYMLINK+="ttyANT%n"

# AntRCT
  SUBSYSTEM=="tty" ACTION=="add" \
  ATTRS{idProduct}=="1007" \
  ATTRS{idVendor}=="0fcf" \
  SYMLINK+="ttyANT%n"
EOF

  chmod a+xr ${UDEV_DIR}
  chmod a+r ${UDEV_RULES_FILE}
}

function writeModprobe() {
  local MODPROBE_DIR=/etc/modprobe.d
  local MODPROBE_FILE=${MODPROBE_DIR}/ant-usb2.conf

  mkdir -p ${MODPROBE_DIR}
  cat <<EOF > ${MODPROBE_FILE}
options usbserial vendor=0x0fcf product=0x1008
EOF

  chmod a+xr ${MODPROBE_DIR}
  chmod a+r ${MODPROBE_FILE}
}

writeUdev
writeModprobe
