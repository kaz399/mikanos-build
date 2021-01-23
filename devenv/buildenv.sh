# Usage: source buildenv.sh

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

export CLANG_TARGET=aarch64-linux-gnu
export SYSROOT=/opt/aarch64-linux-gnu
export MIKANOS_ARCH=ARCH_AARCH64
BASEDIR="${SCRIPT_DIR}/${CLANG_TARGET}"

CROSSBUILD_FLAGS="--sysroot=${SYSROOT} --target=${CLANG_TARGET}"

export CPPFLAGS="${CROSSBUILD_FLAGS} -I$BASEDIR/include/c++/v1 -I$BASEDIR/include -I$BASEDIR/include/freetype2 -nostdlibinc -D__ELF__ -D_LDBL_EQ_DBL -D_GNU_SOURCE -D_POSIX_TIMERS -D${MIKANOS_ARCH}"
export LDFLAGS="-L$BASEDIR/lib"
