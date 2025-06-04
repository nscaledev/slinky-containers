# syntax=docker/dockerfile:1
# SPDX-FileCopyrightText: Copyright (C) SchedMD LLC.
# SPDX-License-Identifier: Apache-2.0

################################################################################

ARG SLURM_VERSION=24.11-latest
ARG SLURM_DIR="slurm-${SLURM_VERSION}"
ARG PARENT_IMAGE=ubuntu:24.04

################################################################################
FROM alpine:latest AS slurm-src

ARG SLURM_VERSION
ARG SLURM_DIR

WORKDIR /workspace/

ADD https://download.schedmd.com/slurm/${SLURM_DIR}.tar.bz2 ${SLURM_DIR}.tar.bz2

RUN <<EOR
# Unpack Slurm Source
set -xeuo pipefail
apk add --no-cache tar
mkdir -p ${SLURM_DIR}
tar --strip-components=1 -jxvf ${SLURM_DIR}.tar.bz2 -C ${SLURM_DIR}
rm ${SLURM_DIR}.tar.bz2
EOR

################################################################################
FROM ${PARENT_IMAGE} AS build

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ARG SLURM_VERSION
ENV SLURM_VERSION=${SLURM_VERSION}
ARG SLURM_DIR

ARG LMOD_VERSION
ENV LMOD_VERSION=${LMOD_VERSION}

USER root
WORKDIR /tmp/

COPY --from=slurm-src /workspace/${SLURM_DIR} ${SLURM_DIR}

COPY patches/ patches/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#debuild
RUN <<EOR
# Patch and Build Slurm
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y upgrade
apt-get -qq -y install --no-install-recommends \
  build-essential fakeroot devscripts equivs curl bc pkg-config
## ROCm smi lib for rsmi gres
apt-get install -qq -y --no-install-recommends librocm-smi-dev
# NVIDIA Management Library for nvml gres
apt-get install -qq -y --no-install-recommends libnvidia-ml-dev
# Download
SLURM_DIR="slurm-${SLURM_VERSION}"
mkdir -p $SLURM_DIR
if [ $(curl -s -Iw '%{http_code}' -o /dev/null https://download.schedmd.com/slurm/${SLURM_DIR}.tar.bz2) -eq 200 ]; then
  curl -s -O https://download.schedmd.com/slurm/${SLURM_DIR}.tar.bz2
  tar --strip-components=1 -jxvf ${SLURM_DIR}.tar.bz2 -C $SLURM_DIR
else
  curl -s -L -H "Accept: application/vnd.github+json" -O https://github.com/SchedMD/slurm/archive/${SLURM_VERSION}.tar.gz
  tar --strip-components=1 -zxvf ${SLURM_VERSION}.tar.gz -C $SLURM_DIR
fi
## Patch
find $(pwd)/patches/ -type f -name "*.patch" -print0 | sort -z | xargs -t0r -n1 patch -p1 -d ${SLURM_DIR} -i
## Build
mk-build-deps -ir --tool='apt-get -qq -y -o Debug::pkgProblemResolver=yes --no-install-recommends' ${SLURM_DIR}/debian/control
( cd $SLURM_DIR && debuild -b -uc -us >/dev/null )
# Download and Build Lmod
LMOD_DIR="Lmod-${LMOD_VERSION}"
mkdir -p $LMOD_DIR
curl -s -L -O https://github.com/TACC/Lmod/archive/refs/tags/${LMOD_VERSION}.tar.gz
tar --strip-components=1 -xvf ${LMOD_VERSION}.tar.gz -C ${LMOD_DIR}
## Build deb package
mk-build-deps -ir --tool='apt-get -qq -y -o Debug::pkgProblemResolver=yes --no-install-recommends' ${LMOD_DIR}/debian/control
( cd $LMOD_DIR && debuild -b -uc -us >/dev/null )
## Cleanup
apt-get clean && rm -rf /var/lib/apt/lists/*
EOR

################################################################################
#ARG PARENT_IMAGE=ubuntu:24.04
#FROM ${PARENT_IMAGE} AS pyxis
#
#SHELL ["bash", "-c"]
#
#ARG DEBIAN_FRONTEND=noninteractive
#
#ARG SLURM_VERSION
#ENV SLURM_VERSION=${SLURM_VERSION}
#
#ARG PYXIS_VERSION
#
#USER root
#WORKDIR /tmp/
#
#COPY --from=build /tmp/*.deb /tmp/
#
#RUN <<EOR
## Download and Build Pyxis Slurm plugin
#set -xeuo pipefail
#apt-get -qq update
#apt-get -qq -y upgrade
#apt-get -qq -y install --no-install-recommends build-essential ca-certificates curl debhelper devscripts
#apt-get -qq -y install --no-install-recommends ./slurm-smd-dev_24.11.4-1_amd64.deb ./slurm-smd_24.11.4-1_amd64.deb
#curl -s -L https://github.com/NVIDIA/pyxis/archive/refs/tags/v${PYXIS_VERSION}.tar.gz -o pyxis-${PYXIS_VERSION}.tar.gz
#tar xf pyxis-${PYXIS_VERSION}.tar.gz
#( cd pyxis-${PYXIS_VERSION} && make orig && make deb )
#EOR

################################################################################
FROM ${PARENT_IMAGE} AS base

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

ARG SLURM_VERSION
ENV SLURM_VERSION=${SLURM_VERSION}

USER root
WORKDIR /tmp/

ARG SLURM_USER=slurm
ARG SLURM_USER_UID=401
ARG SLURM_USER_GID=401

RUN <<EOR
# Create SlurmUser
set -xeuo pipefail
groupadd --system --gid=${SLURM_USER_GID} ${SLURM_USER}
useradd --system --no-log-init --uid=${SLURM_USER_UID} --gid=${SLURM_USER_GID} --shell=/usr/sbin/nologin ${SLURM_USER}
EOR

RUN <<EOR
# Remove Users
set -xeuo pipefail
for user in $(ls /home/); do
  userdel --remove $user
done
EOR

COPY --from=build /tmp/*.deb /tmp/

RUN <<EOR
# Install Dependencies
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y upgrade
# Init System
apt-get -qq -y install --no-install-recommends \
  supervisor tini
apt-get clean && rm -rf /var/lib/apt/lists/*
EOR

################################################################################
# SLURM: slurmctld
# BUILD: `docker build --target=slurmctld -t [<registry>/]slurmctld:<tag> .`
################################################################################
FROM base AS slurmctld

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  ./slurm-smd-client_[0-9]*.deb \
  ./slurm-smd-dev_[0-9]*.deb \
  ./slurm-smd-doc_[0-9]*.deb \
  ./slurm-smd-slurmctld_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
rm *.deb && apt-get clean && rm -rf /var/lib/apt/lists/*
EOR

COPY files/slurmctld/ /

EXPOSE 6817/tcp
ENTRYPOINT ["entrypoint.sh"]

################################################################################
# SLURM: slurmd
# BUILD: `docker build --target=slurmd -t [<registry>/]slurmd:<tag> .`
################################################################################
FROM base AS slurmd

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

#COPY --from=pyxis /tmp/nvslurm-plugin-pyxis_[0-9]*.deb /tmp/

# Add NVIDIA tools to PATH
ENV PATH="${PATH}:/mnt/nvidia-gpu/sbin:/mnt/nvidia-gpu/bin"

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
#curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.5.0/enroot_3.5.0-1_amd64.deb
apt-get -qq -y install --no-install-recommends --fix-broken \
  gawk \
  ./slurm-smd-client_[0-9]*.deb \
  ./slurm-smd-dev_[0-9]*.deb \
  ./slurm-smd-doc_[0-9]*.deb \
  ./slurm-smd-libnss-slurm_[0-9]*.deb \
  ./slurm-smd-libpam-slurm-adopt_[0-9]*.deb \
  ./slurm-smd-libpmi2-0_[0-9]*.deb \
  ./slurm-smd-slurmd_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb \
  ./lmod_[0-9]*.deb
  #./nvslurm-plugin-pyxis_[0-9]*.deb \
  #./enroot_[0-9]*.deb
# Install sshd and sssd
apt-get -qq -y install --no-install-recommends \
  openssh-server \
  dbus-daemon \
  authselect sssd sssd-ad sssd-ldap sssd-dbus libpam-sss libnss-sss
# Install extra tools
apt-get -qq -y install \
  autoconf \
  autotools-dev \
  bc \
  cmake \
  g++ \
  gcc \
  gfortran \
  git \
  iproute2 \
  libevent-dev \
  libpmix-bin \
  libtool \
  linux-headers-6.8.0-57-generic \
  linux-source-6.8.0 \
  pkg-config \
  python3.12 \
  python3-pip \
  strace \
  tar \
  unzip \
  vim \
  wget \
  xz-utils \
  zlib1g-dev

rm *.deb && apt-get clean && rm -rf /var/lib/apt/lists/*
# Configure
mkdir -p /var/spool/slurmd/
cp -v /etc/nsswitch.conf{,.bak}
sed -i -E "s/^passwd:[[:space:]]+/&slurm /g" /etc/nsswitch.conf
sed -i -E "s/^group:[[:space:]]+/&slurm /g" /etc/nsswitch.conf
mkdir -p /etc/fish/conf.d
rm -f /etc/profile.d/lmod.sh
ln -s /usr/lmod/lmod/init/profile /etc/profile.d/z00_lmod.sh
ln -s /usr/lmod/lmod/init/cshrc /etc/profile.d/z00_lmod.csh
ln -s /usr/lmod/lmod/init/profile.fish /etc/fish/conf.d/z00_lmod.fish
echo "/nscale/sw/modulefiles" > /usr/lmod/lmod/init/.modulespath
echo /mnt/nvidia-gpu/lib/x86_64-linux-gnu > /etc/ld.so.conf.d/nvidia
EOR

COPY files/slurmd/ /

EXPOSE 6818/tcp
ENTRYPOINT ["entrypoint.sh"]

################################################################################
# SLURM: slurmdbd
# BUILD: `docker build --target=slurmdbd -t [<registry>/]slurmdbd:<tag> .`
################################################################################
FROM base AS slurmdbd

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  ./slurm-smd-doc_[0-9]*.deb \
  ./slurm-smd-slurmdbd_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
rm *.deb && apt-get clean && rm -rf /var/lib/apt/lists/*
EOR

EXPOSE 6819/tcp
ENTRYPOINT ["tini", "-g", "--", "slurmdbd", "-D"]

################################################################################
# SLURM: slurmrestd
# BUILD: `docker build --target=slurmrestd -t [<registry>/]slurmrestd:<tag> .`
################################################################################
FROM base AS slurmrestd

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  ./slurm-smd-doc_[0-9]*.deb \
  ./slurm-smd-slurmrestd_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
rm *.deb && apt-get clean && rm -rf /var/lib/apt/lists/*
EOR

EXPOSE 6820/tcp
ENTRYPOINT ["tini", "-g", "--", "slurmrestd"]
CMD ["0.0.0.0:6820"]

################################################################################
# SLURM: sackd
# BUILD: `docker build --target=sackd -t [<registry>/]sackd:<tag> .`
################################################################################
FROM base AS sackd

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

ENV KUBECTL_VERSION=1.33

# Ref: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management
RUN <<EOR
# Install kubectl
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends \
  apt-transport-https ca-certificates curl gnupg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBECTL_VERSION}/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${KUBECTL_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list
chmod 644 /etc/apt/sources.list.d/kubernetes.list
apt-get -qq update
apt-get -qq -y install --no-install-recommends kubectl
apt-get clean && rm -rf /var/lib/apt/lists/*
EOR

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN <<EOR
# Install Slurm Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends --fix-broken \
  ./slurm-smd-client_[0-9]*.deb \
  ./slurm-smd-doc_[0-9]*.deb \
  ./slurm-smd-sackd_[0-9]*.deb \
  ./slurm-smd_[0-9]*.deb
# For: Helm Chart
apt-get -qq -y install --no-install-recommends \
  rsync gettext-base iputils-ping
rm *.deb && apt-get clean && rm -rf /var/lib/apt/lists/*
# Prepare Directories
mkdir -p /run/slurm/
EOR

COPY files/sackd/ /

ENTRYPOINT ["entrypoint.sh"]

################################################################################
# NAME : login
# BUILD: `docker build --target=login -t [<registry>/]login:<tag> .`
################################################################################
FROM sackd AS login

SHELL ["bash", "-c"]

ARG DEBIAN_FRONTEND=noninteractive

USER root
WORKDIR /tmp/

COPY --from=build /tmp/lmod*.deb /tmp/
#COPY --from=pyxis /tmp/nvslurm-plugin-pyxis_[0-9]*.deb /tmp/

# Ref: https://slurm.schedmd.com/quickstart_admin.html#pkg_install
RUN <<EOR
# Install Packages
set -xeuo pipefail
apt-get -qq update
apt-get -qq -y install --no-install-recommends \
  openssh-server \
  dbus-daemon \
  oddjob-mkhomedir \
  authselect sssd sssd-ad sssd-ldap sssd-dbus libpam-sss libnss-sss
#curl -fSsL -O https://github.com/NVIDIA/enroot/releases/download/v3.5.0/enroot_3.5.0-1_amd64.deb
#apt-get -qq -y install --no-install-recommends \
#  ./nvslurm-plugin-pyxis_[0-9]*.deb \
#  ./enroot_[0-9]*.deb
# Install extra tools
apt-get -qq -y install \
  autoconf \
  autotools-dev \
  bc \
  cmake \
  g++ \
  gcc \
  gfortran \
  git \
  iproute2 \
  libevent-dev \
  libpmix-bin \
  libtool \
  linux-headers-6.8.0-57-generic \
  linux-source-6.8.0 \
  pkg-config \
  python3.12 \
  python3-pip \
  strace \
  tar \
  unzip \
  vim \
  wget \
  xz-utils \
  zlib1g-dev

# Install lmod
apt-get -qq -y install --no-install-recommends ./lmod_[0-9]*.deb
# Install ContainerSSH Agent
apt-get update
apt-get -qq -y install --no-install-recommends \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg-agent \
  software-properties-common
curl -fsSL https://packages.containerssh.io/debian/gpg | apt-key add -
add-apt-repository  "deb [arch=amd64] https://packages.containerssh.io/debian ./"
apt-get -qq update
apt-get -qq -y install --no-install-recommends containerssh-agent
# Clean up
rm *.deb && apt-get clean && rm -rf /var/lib/apt/lists/*
# Configure
mkdir -p /etc/authselect
authselect select sssd with-mkhomedir --force
rm -f /etc/ssh/ssh_host_*
rm -f /etc/profile.d/lmod.sh
mkdir -p /etc/fish/conf.d
ln -s /usr/lmod/lmod/init/profile /etc/profile.d/z00_lmod.sh
ln -s /usr/lmod/lmod/init/cshrc /etc/profile.d/z00_lmod.csh
ln -s /usr/lmod/lmod/init/profile.fish /etc/fish/conf.d/z00_lmod.fish
echo "/nscale/sw/modulefiles" > /usr/lmod/lmod/init/.modulespath
# Remove Packages
apt-get -qq -y remove \
  authselect
apt-get -qq -y autoremove
rm -rf ./*.deb
EOR

COPY files/login/ /

EXPOSE 22/tcp
ENTRYPOINT ["entrypoint.sh"]
