#!/bin/bash
#
#    vtk installer
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

#TODO 
# remove package manager dependency
# check existing installation
if [ $OS == 'centos' ];then
  $SUDO yum install -y libXt-devel freeglut-devel
elif [ $OS == 'ubuntu' ];then
  $SUDO apt install -y libxt-dev freeglut3-dev
fi

PKG_NAME="vtk"
WORKDIR=$HOME/.lib
REPO_URL=https://gitlab.kitware.com/vtk/vtk
TAG=$(git ls-remote --tags $REPO_URL | awk -F/ '{print $3}' | grep -v -e '{}' -e 'rc' | sort -V | tail -n1)
COMMIT_HASH=$(git ls-remote --tags $REPO_URL | grep "$TAG^{}" | awk '{print $1}')
SRCDIR="vtk-$TAG-$COMMIT_HASH"

iecho "$PKG_NAME installation.."
cd $WORKDIR
if [ ! -d $SRCDIR ]; then
  iecho "Downloading vtk $TAG"
  curl -L https://gitlab.kitware.com/vtk/vtk/repository/$TAG/archive.tar.bz2 | tar xjf -
fi
cd $SRCDIR && mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=${LOCAL_DIR} ..
make -s -j$(nproc)
make -s install 1>/dev/null
cd $ROOT
