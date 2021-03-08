# Usage: source buildenv.sh

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

export TARGET_ARCH=aarch64
export SYSROOT="${AARCH64_GCC_PATH}"
export DEVENV_DIR="${SCRIPT_DIR}"

