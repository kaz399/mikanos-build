#!/bin/bash -eu

WORKDIR="$(pwd)"

TOOLCHAIN_DIR=${1:-${HOME}/.mikanos.toolchain}
DOWNLOAD_DIR=${2:-"${WORKDIR}"/downloads}

if [[ -s ${HOME}/.mianos.toolchain_path ]] ; then
    . ${HOME}/.mikanos.toolchain_path
fi

# get source code and binaries

if [[ ! -d "${WORKDIR}/edk2" ]] ; then
    git clone https://github.com/tianocore/edk2.git "${WORKDIR}"/edk2
fi

if [[ ! -d "${WORKDIR}/osbook" ]] ; then
    git clone https://github.com/kaz399/mikanos-build.git  "${WORKDIR}"/osbook  -b local/aarch64
fi

if [[ ! -d "${WORKDIR}/mikanos" ]] ; then
    git clone https://github.com/kaz399/mikanos-aarch64.git "${WORKDIR}"/mikanos -b local/aarch64
fi

if [[ ! -d "${WORKDIR}/freetype2" ]] ; then
    git clone https://github.com/freetype/freetype2.git "${WORKDIR}"/freetype2
fi

if [[ ! -d "${WORKDIR}/musl" ]] ; then
    git clone git://git.musl-libc.org/musl "${WORKDIR}"/musl
fi

if [[ ! -d "${WORKDIR}/seabios" ]] ; then
    git clone https://git.seabios.org/seabios.git "${WORKDIR}"/seabios
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

if [[ ! -f "${DOWNLOAD_DIR}/x86_64-elf.tar.gz" ]] ; then
    echo "downloading libraries for x86_64"
    wget -P "${DOWNLOAD_DIR}" https://github.com/uchan-nos/mikanos-build/releases/download/v2.0/x86_64-elf.tar.gz
fi

# build environment settings

DEVENV_DIR="${WORKDIR}"/osbook/devenv/aarch64-linux-gnu
CPUS=$(nproc --ignore=2)

mkdir -p "${TOOLCHAIN_DIR}"
if [[ ! -d "$(dirname ${DEVENV_DIR})" ]] ; then
    echo "$(dirname ${DEVENV_DIR}) is not found (failed to clone?)"
    exit 1
fi
mkdir -p "${DEVENV_DIR}"

# expand archives

if [[ ! -d "clang+llvm-11.0.0-aarch64-linux-gnu" ]] ; then
    tar xvf "${DOWNLOAD_DIR}"/clang+llvm-11.0.0-aarch64-linux-gnu.tar.xz
    cd "${WORKDIR}"/clang+llvm-11.0.0-aarch64-linux-gnu
    cp -vr * "${DEVENV_DIR}"
    cd "${WORKDIR}"
fi

if [[ ! -d "${TOOLCHAIN_DIR}/aarch64-linux-gnu-gcc" ]] ; then
    if [[ ! -d "gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu" ]] ; then
        tar xvf "${DOWNLOAD_DIR}"/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu.tar.xz -C "${TOOLCHAIN_DIR}"
        cd  "${TOOLCHAIN_DIR}"
        ln -s gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu aarch64-linux-gnu-gcc
        cd aarch64-linux-gnu-gcc/bin/
        for file in aarch64-none-linux-gnu-*; do ln -s $file $(echo $file | sed -e 's/-none//g'); done
        cd "${WORKDIR}"
    fi
fi

if [[ ! -d "${WORKDIR}/osbook/devenv/x86_64-elf" ]] ; then
    tar xvf "${DOWNLOAD_DIR}/x86_64-elf.tar.gz" -C "${WORKDIR}"/osbook/devenv
fi
echo "export PATH=\"${TOOLCHAIN_DIR}/aarch64-linux-gnu-gcc/bin:\${PATH}\"" > ${HOME}/.mikanos.toolchain_path
echo "export MIKANOS_TOOLCHAIN_PATH=\"${TOOLCHAIN_DIR}\"" >> ${HOME}/.mikanos.toolchain_path

. ${HOME}/.mikanos.toolchain_path

# build

# musl

#rm -fr musl-1.2.2
#tar xvf "${DOWNLOAD_DIR}"/musl-1.2.2.tar.gz
cd "${WORKDIR}"/musl
git clean -dfx
./configure --target=aarch64-linux-gnu --disable-shared --prefix=${DEVENV_DIR}
make -j${CPUS} install

# freetype2

cd "${WORKDIR}"/freetype2
git clean -dfx
./autogen.sh
./configure --target=aarch64-linux-gnu --disable-shared --prefix=${DEVENV_DIR}
make -j${CPUS} install

# edk2

cd "${WORKDIR}"/edk2
git clean -dfx
git submodule init
git submodule update
cd "${WORKDIR}"/edk2/BaseTools
make
cd "${WORKDIR}"/edk2
set +u
. "${WORKDIR}"/edk2/edksetup.sh
set -u
#BUILD_COMPILER=GCC5
BUILD_COMPILER=CLANG38
export ${BUILD_COMPILER}_AARCH64_PREFIX=aarch64-linux-gnu-
build -a AARCH64 -t ${BUILD_COMPILER} -p ArmVirtPkg/ArmVirtQemu.dsc
dd if=/dev/zero of=${DEVENV_DIR}/OVMF_CODE.fd bs=1M count=64
dd if="${WORKDIR}"/edk2/Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_EFI.fd of=${DEVENV_DIR}/OVMF_CODE.fd conv=notrunc
dd if=/dev/zero of=${DEVENV_DIR}/OVMF_VARS.fd bs=1M count=64
dd if="${WORKDIR}"/edk2//Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_VARS.fd of=${DEVENV_DIR}/OVMF_VARS.fd conv=notrunc

ln -s ../mikanos/MikanLoaderPkg .

# seabios

cd "${WORKDIR}"/seabios
git clean -dfx
cp "${WORKDIR}"/osbook/aarch64-buildenv/seabios.config "${WORKDIR}"/seabios/.config
make
cp "${WORKDIR}"/seabios/out/vgabios.bin "${WORKDIR}"/seabios/vgabios-ramfb.bin


# copy activate.sh

cp "${WORKDIR}"/osbook/aarch64-buildenv/activate.sh "${WORKDIR}"

echo "complete"

