# Usage: source buildenv.sh

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

export TARGET_ARCH=aarch64
export MIKANOS_ARCH=ARCH_AARCH64
export MIKANOS_TARGET_LIBDIR=aarch64-linux-gnu
export CLANG_TARGET=aarch64-linux-gnu
export SYSROOT=${MIKANOS_TOOLCHAIN_PATH}/aarch64-linux-gnu-gcc

BASEDIR="${SCRIPT_DIR}/${MIKANOS_TARGET_LIBDIR}"
CROSSBUILD_FLAGS="--sysroot=${SYSROOT} --target=${CLANG_TARGET}"

export CPPFLAGS="${CROSSBUILD_FLAGS} -I${BASEDIR}/include/c++/v1 -I${BASEDIR}/include -I${BASEDIR}/include/freetype2 -nostdlibinc -D__ELF__ -D_LDBL_EQ_DBL -D_GNU_SOURCE -D_POSIX_TIMERS -D${MIKANOS_ARCH}=1"
export LDFLAGS="-L${BASEDIR}/lib"
