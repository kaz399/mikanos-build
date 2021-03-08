
# deactivate

SCRIPT_DIR=$(cd $(dirname ${BASH_SOURCE:-$0}); pwd)
TARGET_ARCH=${1:-aarch64}

if [ -n "${1}" ] ; then
    shift
fi

if [ ! -s "${SCRIPT_DIR}/osbook/devenv/buildenv-${TARGET_ARCH}.sh" ] ; then
    echo "ERROR: ${TARGET_ARCH} is not supported"
    return
fi

function deactivate () {
    echo deactivate
    export PATH=${ORIG_PATH}
    case ${BASH}${ZSH_NAME} in
        *bash* )
            PS1=${ORIG_PS1}
            PROMPT_COMMAND=${ORIG_PROMPT_COMMAND}
            unset ORIG_PS1
            unset ORIG_PROMPT_COMMAND
            ;;
        *zsh* )
            PROMPT=${ORIG_PROMPT}
            unset ORIG_PROMPT
            ;;
    esac
    unset CLANG_TARGET
    unset CONF_PATH
    unset CPPFLAGS
    unset EDK_TOOLS_PATH
    unset LDFLAGS
    unset MIKANOS_ARCH
    unset MIKANOS_COMPILEDB
    unset PYTHON_COMMAND
    unset PYTHONHASHSEED
    unset SYSROOT
    unset WORKSPACE
}

function bear_wrapper () {
    if [ -f ${MIKANOS_COMPILEDB} ] ; then
        bear_opt="-a"
    else
        bear_opt=""
    fi
    \bear $bear_opt -o ${MIKANOS_COMPILEDB} $@
}

# check re-activation

if [[ -n "${ORIG_PS1}" || -n "${ORIG_PROMPT}" ]] ; then
    echo 're-activate'
    deactivate
fi

# set prompt

echo ${BASH}${ZSH_NAME}
case ${BASH}${ZSH_NAME} in
    *bash* )
        ORIG_PS1=${PS1}
        ORIG_PROMPT_COMMAND=${PROMPT_COMMAND}
        ACTIVATE_DIR=$(pwd)

        function __set_prompt_osdev () {
            PS1=${ORIG_PS1}
            ${ORIG_PROMPT_COMMAND}
            PS1="\[\e[1;34m\](osdev-aarch64)\[\e[m\]:${PS1}"
        }

        PROMPT_COMMAND=__set_prompt_osdev
        ;;
    *zsh* )
        ORIG_PROMPT=${PROMPT}
        ACTIVATE_DIR=$(pwd)
        export PROMPT="osdev:%F{cyan}(osdev-${TARGET_ARCH})%f:${ORIG_PROMPT}"
        ;;
esac


# misc

ORIG_PATH=${PATH}
export PATH=${ORIG_PATH}:${SCRIPT_DIR}/osbook/devenv/
export MIKANOS_COMPILEDB=${SCRIPT_DIR}/mikanos/compile_commands.json
export QEMU_LIBPATH="-L ${SCRIPT_DIR}/seabios"
#-L /usr/share/qemu -L /usr/share/seabios"

alias edk="cd ${SCRIPT_DIR}/edk2"
alias osb="cd ${SCRIPT_DIR}/osbook"
alias mik="cd ${SCRIPT_DIR}/mikanos"
alias bear="bear_wrapper"
alias rk="run_qemu.sh ${SCRIPT_DIR}/edk2/Build/MikanLoaderX64/DEBUG_CLANG38/X64/Loader.efi ${SCRIPT_DIR}/mikanos/kernel/kernel.elf"
alias ra="run_qemu-aarch64.sh ${SCRIPT_DIR}/edk2/Build/MikanLoaderAARCH64/DEBUG_CLANG38/AARCH64/Loader.efi ${SCRIPT_DIR}/mikanos/kernel/kernel.elf"
alias cdr="cd ${SCRIPT_DIR}"

# source scripts

\pushd . > /dev/null

if [ -s "${HOME}/.mikanos.toolchain_path" ] ; then
    echo "source toolchain definition"
    source ${HOME}/.mikanos.toolchain_path
else
    ls -al "${HOME}/.mianos.toolchain_path"
fi

\cd ${SCRIPT_DIR}/edk2
source ./edksetup.sh
\cd ${SCRIPT_DIR}/osbook
source ./devenv/buildenv-${TARGET_ARCH}.sh

\popd > /dev/null
