#!/bin/bash
#
#    CUDA & Cudnn installer
#     - Refered nvidia cuda dockerfile
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

. $ROOT/envset.sh

if [ ! $(whoami) == 'root' ];then
    eecho "run it with sudo"
    exit 1
fi

if [ $OS == "ubuntu" ] || [ $OS == "debian" ];then
    NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
        NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 && \
        apt-key adv --fetch-keys http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64/7fa2af80.pub && \
        apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub && \
        echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub && \
        echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/cuda.list
    echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1604/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list

    export CUDA_VERSION=8.0.61
    export CUDA_PKG_VERSION=8-0=$CUDA_VERSION-1
    export CUDNN_VERSION=6.0.21

    apt update
    apt-get install -y --no-install-recommends \
            cuda-core-$CUDA_PKG_VERSION \
            cuda-nvrtc-$CUDA_PKG_VERSION \
            cuda-nvgraph-$CUDA_PKG_VERSION \
            cuda-cusolver-$CUDA_PKG_VERSION \
            cuda-cublas-8-0=8.0.61.2-1 \
            cuda-cufft-$CUDA_PKG_VERSION \
            cuda-curand-$CUDA_PKG_VERSION \
            cuda-cusparse-$CUDA_PKG_VERSION \
            cuda-npp-$CUDA_PKG_VERSION \
            cuda-cudart-$CUDA_PKG_VERSION \
            cuda-misc-headers-$CUDA_PKG_VERSION \
            cuda-command-line-tools-$CUDA_PKG_VERSION \
            cuda-nvrtc-dev-$CUDA_PKG_VERSION \
            cuda-nvml-dev-$CUDA_PKG_VERSION \
            cuda-nvgraph-dev-$CUDA_PKG_VERSION \
            cuda-cusolver-dev-$CUDA_PKG_VERSION \
            cuda-cublas-dev-8-0=8.0.61.2-1 \
            cuda-cufft-dev-$CUDA_PKG_VERSION \
            cuda-curand-dev-$CUDA_PKG_VERSION \
            cuda-cusparse-dev-$CUDA_PKG_VERSION \
            cuda-npp-dev-$CUDA_PKG_VERSION \
            cuda-cudart-dev-$CUDA_PKG_VERSION \
            cuda-driver-dev-$CUDA_PKG_VERSION \
            libcudnn7=$CUDNN_VERSION-1+cuda8.0 \
            libcudnn7-dev=$CUDNN_VERSION-1+cuda8.0 && \
            ${SUDO} ln -s /usr/local/cuda-8.0 /usr/local/cuda

    echo "/usr/local/cuda/lib64" >> /etc/ld.so.conf.d/cuda.conf && ldconfig

elif [ $OS == "centos" ];then
    NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
        curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/7fa2af80.pub | sed '/^Version/d' > /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA && \
        echo "$NVIDIA_GPGKEY_SUM  /etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" | sha256sum -c --strict -

    printf "[cuda]\nname=cuda\nbaseurl=http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-NVIDIA" > /etc/yum.repos.d/cuda.repo

    yum install -y cuda-8-0
        
    CUDNN_DOWNLOAD_SUM=9b09110af48c9a4d7b6344eb4b3e344daa84987ed6177d5c44319732f3bb7f9c && \
        curl -fsSL http://developer.download.nvidia.com/compute/redist/cudnn/v6.0/cudnn-8.0-linux-x64-v6.0.tgz -O && \
        echo "$CUDNN_DOWNLOAD_SUM  cudnn-8.0-linux-x64-v6.0.tgz" | sha256sum -c - && \
        tar --no-same-owner -xzf cudnn-8.0-linux-x64-v6.0.tgz -C /usr/local && \
        rm cudnn-8.0-linux-x64-v6.0.tgz && \
        ldconfig
fi
