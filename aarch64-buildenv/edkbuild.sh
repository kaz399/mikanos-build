#!/bin/bash -eu

TOOLCHAIN_DIR=${1:-${HOME}/.mikanos.toolchain}
DOWNLOAD_DIR=${2:-./downloads}

if [[ -f ${HOME}/.toolchain_path ]] ; then
    . ${HOME}/.mikanos.toolchain_path
fi

DEVENV_DIR=$(pwd)/osbook/devenv/aarch64-linux-gnu
CPUS=$(nproc --ignore=2)

# build
# edk2
pushd edk2
set +u
. ./edksetup.sh
set -u
#BUILD_COMPILER=GCC5
BUILD_COMPILER=CLANG38
export ${BUILD_COMPILER}_AARCH64_PREFIX=aarch64-linux-gnu-
build -a AARCH64 -t ${BUILD_COMPILER} -p ArmVirtPkg/ArmVirtQemu.dsc ${BUILDARG:-}

dd if=/dev/zero of=${DEVENV_DIR}/OVMF_CODE.fd bs=1M count=64
dd if=./Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_EFI.fd of=${DEVENV_DIR}/OVMF_CODE.fd conv=notrunc
dd if=/dev/zero of=${DEVENV_DIR}/OVMF_VARS.fd bs=1M count=64
dd if=./Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_VARS.fd of=${DEVENV_DIR}/OVMF_VARS.fd conv=notrunc

popd

echo "complete"

