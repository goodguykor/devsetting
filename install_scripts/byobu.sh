#!/bin/bash

set -e

ROOT=$(cd $(dirname ${BASH_SOURCE[0]})/.. && pwd)
. $ROOT/envset.sh

bash $ROOT/install_scripts/tmux.sh

REPO_URL=https://github.com/dustinkirkland/byobu

echo "Byobu installation.. pwd: $PWD, root: $ROOT"

cd $HOME/.lib

if [ ! -d byobu ];then
  git clone $REPO_URL
fi

cd byobu && git pull && \
./autogen.sh && ./configure --prefix="$HOME/.local" && \
make -j$(nproc) && make install

cd $ROOT
