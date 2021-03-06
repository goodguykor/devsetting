#!/bin/bash
#
#    freetype2 installer
#
#    Copyright (C) 2017 Gwangmin Lee
#    
#    Author: Gwangmin Lee <gwangmin0123@gmail.com>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

set -e

FILENAME=`basename ${BASH_SOURCE[0]}`
FILENAME=${FILENAME%%.*}
DONENAME="DONE$FILENAME"
if [ ! -z ${!DONENAME+x} ];then
  return 0
fi
let DONE$FILENAME=1

ROOT=$(cd $(dirname ${BASH_SOURCE[0]})/.. && pwd)
PWD=$(pwd)
. $ROOT/envset.sh

. $ROOT/install_scripts/libpng.sh

PKG_NAME="freetype2"
REPO_URL="https://git.savannah.gnu.org/git/freetype/freetype2.git"
TAG=$(git ls-remote -t $REPO_URL | grep -v -e '{}\|freetype\|start\|import\|BETA\|REAL\|beta' | cut -d/ -f3 | sort -V | tail -n1)
VER='21.0.15'
DOWN_URL="https://git.savannah.gnu.org/cgit/freetype/freetype2.git/snapshot/freetype2-$TAG.tar.gz"
FOLDER="$PKG_NAME*"
VERFILE=""
if $(pkg-config --exists $PKG_NAME);then
  INSTALLED_VERSION=$(pkg-config --modversion $PKG_NAME)
fi

if [ ! -z $REINSTALL ] || [ -z $INSTALLED_VERSION ] || [ $VER != $INSTALLED_VERSION ]; then
  iecho "$PKG_NAME $VER installation.. install location: $LOCAL_DIR"

  mkdir -p $TMP_DIR && cd $TMP_DIR
  curl -L $DOWN_URL | tar xz
  cd $FOLDER
  ./autogen.sh
  ./configure --prefix=${LOCAL_DIR} --with-sysroot=${LOCAL_DIR}/local
  make -s -j$(nproc) && make -s install 1>/dev/null

  cd $ROOT && rm -rf $TMP_DIR
else
  gecho "$PKG_NAME $VER is already installed"
fi

cd $ROOT
