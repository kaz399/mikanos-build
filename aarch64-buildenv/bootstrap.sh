#!/bin/bash -eu

if git rev-parse 2> /dev/null ; then
    REPOTOP="$(git rev-parse --show-superproject-working-tree --show-toplevel | head -1)"
    WORKDIR="$(cd ${REPOTOP}/../ && pwd)"
    echo "Inside of a git repository"
    echo "Go to ${WORKDIR}"
    cd "${WORKDIR}"
else
    echo "Outside of a git repository"
    WORKDIR="$(pwd)"
fi

TOOLCHAIN_DIR=${1:-${HOME}/.mikanos.toolchain}
DOWNLOAD_DIR=${2:-"${WORKDIR}"/downloads}

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

DEVENV_DIR="${WORKDIR}/osbook/devenv/aarch64-linux-gnu"
CPUS=$(nproc --ignore=2)

mkdir -p "${TOOLCHAIN_DIR}"
if [[ ! -d "$(dirname ${DEVENV_DIR})" ]] ; then
    echo "$(dirname ${DEVENV_DIR}) is not found (failed to clone?)"
    exit 1
fi
mkdir -p "${DEVENV_DIR}"

# expand archives

if [[ ! -d "clang+llvm-11.0.0-aarch64-linux-gnu" ]] ; then
    tar xvf "${DOWNLOAD_DIR}/clang+llvm-11.0.0-aarch64-linux-gnu.tar.xz" -C "${WORKDIR}"
fi
cd "${WORKDIR}/clang+llvm-11.0.0-aarch64-linux-gnu"
cp -vr * "${DEVENV_DIR}"

if [[ ! -e "${WORKDIR}/aarch64-linux-gnu" ]] ; then
    if [[ ! -d "gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu" ]] ; then
        tar xvf "${DOWNLOAD_DIR}/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu.tar.xz" -C "${WORKDIR}"
        cd "${WORKDIR}"
        ln -s gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu aarch64-linux-gnu
        cd "${WORKDIR}/aarch64-linux-gnu/bin/"
        for file in aarch64-none-linux-gnu-*; do ln -s $file $(echo $file | sed -e 's/-none//g'); done
        cd "${WORKDIR}"
    fi
fi
cp -v "${WORKDIR}/aarch64-linux-gnu/lib/gcc/aarch64-none-linux-gnu/10.2.1/libgcc.a" "${DEVENV_DIR}/lib/libgcc.a"

if [[ ! -d "${WORKDIR}/osbook/devenv/x86_64-elf" ]] ; then
    tar xvf "${DOWNLOAD_DIR}/x86_64-elf.tar.gz" -C "${WORKDIR}"/osbook/devenv
fi

# add aarch64 gcc to PATH
export PATH="${WORKDIR}/aarch64-linux-gnu/bin:${PATH}"


# build aarch64 libraries

# musl

#rm -fr musl-1.2.2
#tar xvf "${DOWNLOAD_DIR}"/musl-1.2.2.tar.gz
cd "${WORKDIR}/musl"
git clean -dfx
./configure --target=aarch64-linux-gnu --disable-shared --prefix="${DEVENV_DIR}"
make -j${CPUS} install

# freetype2

cd "${WORKDIR}/freetype2"
git clean -dfx
./autogen.sh
./configure --target=aarch64-linux-gnu --disable-shared --prefix="${DEVENV_DIR}"
make -j${CPUS} install

# edk2

cd "${WORKDIR}/edk2"
if [ -n "${WORKSPACE:-}" ] ; then
    unset WORKSPACE
fi
git clean -dfx
git submodule init
git submodule update
cd "${WORKDIR}/edk2/BaseTools"
make
cd "${WORKDIR}/edk2"
set +u
. "${WORKDIR}/edk2/edksetup.sh"
set -u
#BUILD_COMPILER=GCC5
BUILD_COMPILER=CLANG38
export ${BUILD_COMPILER}_AARCH64_PREFIX=aarch64-linux-gnu-
build -a AARCH64 -t ${BUILD_COMPILER} -p ArmVirtPkg/ArmVirtQemu.dsc
dd if=/dev/zero of="${DEVENV_DIR}/OVMF_CODE.fd" bs=1M count=64
dd if="${WORKDIR}/edk2/Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_EFI.fd" of="${DEVENV_DIR}/OVMF_CODE.fd" conv=notrunc
dd if=/dev/zero of="${DEVENV_DIR}/OVMF_VARS.fd" bs=1M count=64
dd if="${WORKDIR}/edk2//Build/ArmVirtQemu-AARCH64/DEBUG_${BUILD_COMPILER}/FV/QEMU_VARS.fd" of="${DEVENV_DIR}/OVMF_VARS.fd" conv=notrunc

if [[ ! -e MikanLoaderPkg ]] ; then
    ln -s ../mikanos/MikanLoaderPkg .
fi

# seabios

cd "${WORKDIR}/seabios"
git clean -dfx
cp "${WORKDIR}/osbook/aarch64-buildenv/seabios.config" "${WORKDIR}/seabios/.config"
make
cp "${WORKDIR}/seabios/out/vgabios.bin" "${WORKDIR}/seabios/vgabios-ramfb.bin"


# copy activate.sh

cp "${WORKDIR}/osbook/aarch64-buildenv/activate.sh" "${WORKDIR}"

echo ""
echo "*** complete"

