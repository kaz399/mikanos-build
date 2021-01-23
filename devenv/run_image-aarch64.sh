#!/bin/sh -ex

if [ $# -lt 1 ]
then
    echo "Usage: $0 <image name>"
    exit 1
fi

DEVENV_DIR=$(dirname "$0")
DISK_IMG=$1
ARCH=aarch64-linux-gnu

if [ ! -f $DISK_IMG ]
then
    echo "No such file: $DISK_IMG"
    exit 1
fi

qemu-system-aarch64 \
    -machine virt \
    -cpu cortex-a57 \
    -m 1G \
    -drive if=pflash,format=raw,readonly,file=$DEVENV_DIR/$ARCH/OVMF_CODE.fd \
    -drive if=pflash,format=raw,file=$DEVENV_DIR/$ARCH/OVMF_VARS.fd \
    -drive format=raw,file=$DISK_IMG \
    -device nec-usb-xhci,id=xhci \
    -device usb-mouse \
    -device usb-kbd \
    -monitor stdio \
    -device ramfb \
    $QEMU_OPTS
