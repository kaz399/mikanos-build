# Usage: source buildenv.sh

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

export TARGET_ARCH=x86_64
export MIKANOS_ARCH=ARCH_X86_64
export MIKANOS_TARGET_LIBDIR=x86_64-elf
export CLANG_TARGET=x86_64-linux-gnu
export SYSROOT=

BASEDIR="${SCRIPT_DIR}/${MIKANOS_TARGET_LIBDIR}"
CROSSBUILD_FLAGS=

export CPPFLAGS="${CROSSBUILD_FLAGS} -I${BASEDIR}/include/c++/v1 -I${BASEDIR}/include -I${BASEDIR}/include/sys -I${BASEDIR}/include/freetype2 -nostdlibinc -D__ELF__ -D_LDBL_EQ_DBL -D_GNU_SOURCE -D_POSIX_TIMERS -D${MIKANOS_ARCH}=1"
export LDFLAGS="-L${BASEDIR}/lib"
