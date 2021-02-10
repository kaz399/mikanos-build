#!/bin/bash -eu

if [[ ! -x llvm.sh ]] ; then
    wget https://apt.llvm.org/llvm.sh
    chmod +x llvm.sh
fi
sudo ./llvm.sh 11
sudo ./update-alternatives-clang.sh 11 50

sudo update-alternatives --set llvm-config /usr/bin/llvm-config-11
sudo update-alternatives --set clang /usr/bin/clang-11

sudo apt install -y build-essential acpica-tools
sudo apt install -y autoconf libtool
sudo apt install -y uuid-dev

