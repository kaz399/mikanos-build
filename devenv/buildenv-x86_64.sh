# Usage: source buildenv.sh

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)

export TARGET_ARCH=x86_64
export DEVENV_DIR="${SCRIPT_DIR}"

