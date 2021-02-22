#!/bin/bash -eu

TOOLCHAIN_DIR=${1:-${HOME}/.mikanos.toolchain}
DOWNLOAD_DIR=${2:-./downloads}

if [[ -f ${HOME}/.toolchain_path ]] ; then
    . ${HOME}/.mikanos.toolchain_path
fi

# get source code and binaries

if [[ ! -d "edk2" ]] ; then
    git clone https://github.com/tianocore/edk2.git        edk2
fi

if [[ ! -d "osbook" ]] ; then
    git clone https://github.com/kaz399/mikanos-build.git  osbook  -b local/aarch64
fi

if [[ ! -d "mikanos" ]] ; then
    git clone https://github.com/kaz399/mikanos-aarch64.git mikanos -b local/aarch64
fi

if [[ ! -d "freetype2" ]] ; then
    git clone https://github.com/freetype/freetype2.git    freetype2
fi

if [[ ! -d "musl" ]] ; then
    git clone git://git.musl-libc.org/musl                 musl
fi

#if [[ ! -f "${DOWNLOAD_DIR}/musl-1.2.2.tar.gz" ]] ; then
#    wget -P "${DOWNLOAD_DIR}" https://musl.libc.org/releases/musl-1.2.2.tar.gz
#fi

if [[ ! -f "${DOWNLOAD_DIR}/clang+llvm-11.0.0-aarch64-linux-gnu.tar.xz" ]] ; then
    echo "downloading clang-11 (aarch64)"
    wget -P "${DOWNLOAD_DIR}" https://github.com/llvm/llvm-project/releases/download/llvmorg-11.0.0/clang+llvm-11.0.0-aarch64-linux-gnu.tar.xz
fi

if ! which aarch64-none-linux-gnu-gcc ; then
    if [[ ! -f "${DOWNLOAD_DIR}/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu.tar.xz" ]] ; then
        echo "downloading gcc-10.2 (cross compiler: x86_64->aarch64)"
        wget -P "${DOWNLOAD_DIR}" https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu.tar.xz
    fi
fi

# build environment settings

DEVENV_DIR=$(pwd)/osbook/devenv/aarch64-linux-gnu
CPUS=$(nproc --ignore=2)

mkdir -p "${TOOLCHAIN_DIR}"
mkdir -p "${DEVENV_DIR}"

# expand archives

if [[ ! -d "clang+llvm-11.0.0-aarch64-linux-gnu" ]] ; then
    tar xvf "${DOWNLOAD_DIR}"/clang+llvm-11.0.0-aarch64-linux-gnu.tar.xz
    pushd clang+llvm-11.0.0-aarch64-linux-gnu
    cp -vr * "${DEVENV_DIR}"
    popd
fi

if [[ ! -d "${TOOLCHAIN_DIR}/aarch64-linux-gnu-gcc" ]] ; then
    if [[ ! -d "gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu" ]] ; then
        tar xvf "${DOWNLOAD_DIR}"/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu.tar.xz -C "${TOOLCHAIN_DIR}"
        pushd "${TOOLCHAIN_DIR}"
        ln -s gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu aarch64-linux-gnu-gcc
        pushd aarch64-linux-gnu-gcc/bin/
        for file in aarch64-none-linux-gnu-*; do ln -s $file $(echo $file | sed -e 's/-none//g'); done
        popd
        popd
    fi
fi

echo "export PATH=\"${TOOLCHAIN_DIR}/aarch64-linux-gnu-gcc/bin:${PATH}\"" > ${HOME}/.mikanos.toolchain_path

. ${HOME}/.mikanos.toolchain_path

# build

# musl

#rm -fr musl-1.2.2
#tar xvf "${DOWNLOAD_DIR}"/musl-1.2.2.tar.gz
pushd musl
git clean -dfx
./configure --target=aarch64-linux-gnu --disable-shared --prefix=${DEVENV_DIR}
make -j${CPUS} install
popd

# freetype2

pushd freetype2
git clean -dfx
./autogen.sh
./configure --target=aarch64-linux-gnu --disable-shared --prefix=${DEVENV_DIR}
make -j${CPUS} install
popd

# edk2

pushd edk2
git clean -dfx
git submodule init
git submodule update
pushd BaseTools
make
popd
set +u
. ./edksetup.sh
set -u
#BUILD_COMPILER=GCC5
BUILD_COMPILER=CLANG38
export ${BUILD_COMPILER}_AARCH64_PREFIX=aarch64-linux-gnu-
build -a AARCH64 -t ${BUILD_COMPILER} -p ArmVirtPkg/ArmVirtQemu.dsc
dd if=/dev/zero of=${DEVENV_DIR}/OVMF_CODE.fd bs=1M count=64
dd if=./Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_EFI.fd of=${DEVENV_DIR}/OVMF_CODE.fd conv=notrunc
dd if=/dev/zero of=${DEVENV_DIR}/OVMF_VARS.fd bs=1M count=64
dd if=./Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_VARS.fd of=${DEVENV_DIR}/OVMF_VARS.fd conv=notrunc

ln -s ../mikanos/MikanLoaderPkg .

popd

echo "complete"

