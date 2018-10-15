#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# source the environment file
. "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/.env"

# configure dpkg for noninteractive access
export DEBIAN_FRONTEND=noninteractive

# update the base system
apt-get -qqy update
apt-get -qqy upgrade

# install packages
apt-get -qqy install \
  curl \
  git \
  htop \
  iftop \
  iotop \
  locales \
  nfs-common \
  snapd \
  strace \
  traceroute \
  tzdata \
  vim \
  wget \
  zfsutils-linux

# install lxd and give access to boot2lxd user
snap install lxd
usermod -aG lxd "$BOOT2LXD_USER"

# cleanup virtualbox files
rm -f "/home/$BOOT2LXD_USER/VBoxGuestAdditions_"*.iso || true
find /var/log -type f -name 'vboxadd-*' -delete

# cleanup apt lists, logs etc
find /var/lib/apt/lists -type f -delete
find /var/log -type f -regex '.+\\.[0-9]+' -delete

# write zeroes to free space to compact image
dd if=/dev/zero of=/zero bs=1M || true
rm -f /zero
sync
