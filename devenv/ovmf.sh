#!/usr/bin/bash -eu

dd if=/dev/zero of=OVMF_CODE.fd bs=1M count=64
dd if=$1 of=OVMF_CODE.fd conv=notrunc

dd if=/dev/zero of=OVMF_VARS.fd bs=1M count=64
dd if=$2 of=OVMF_VARS.fd conv=notrunc
