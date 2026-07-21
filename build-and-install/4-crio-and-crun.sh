#!/bin/bash

# WARNING: the following script assumes ubuntu. Won't work on other distros!

set -o errexit
set -o nounset
set -o pipefail

# Install vanilla CRI-O; use v1.33 by default since that's what we use, unless the caller
# invokes this script with another version as argument.
if command -v crio > /dev/null; then
  echo vanilla cri-o is already installed
else
  CRIO_VERSION=${1:-v1.33}
  apt-get update -y && apt-get install -y software-properties-common curl
  curl -fsSL https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/Release.key |
      gpg --batch --yes --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
  echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://download.opensuse.org/repositories/isv:/cri-o:/stable:/$CRIO_VERSION/deb/ /" |
      tee /etc/apt/sources.list.d/cri-o.list
  apt-get update -y && apt-get install -y cri-o
fi

# We installed vanilla CRI-O because to run correctly CRI-O needs a bunch of config files; the
# vanilla installation makes sure they exist and are correct. Now, let's build our custom CRI-O
# and its dependency crun, and use the resulting binaries to replace vanilla crio and crun.

# The following build instructions are based on
# https://github.com/matte21/stinglet-cri-o/blob/fg-cgroups/install.md#build and
# https://github.com/matte21/stinglet-crun/blob/fg-cgroups/README.md

# First, install build dependencies
apt-get update -qq && apt-get install -y \
  make git gcc build-essential pkgconf libtool libsystemd-dev libprotobuf-c-dev \
  libcap-dev libseccomp-dev libyajl-dev go-md2man autoconf python3 automake libbtrfs-dev \
  libassuan-dev libglib2.0-dev libc6-dev libgpgme-dev libgpg-error-dev libselinux1-dev \
  libudev-dev software-properties-common jq golang-github-containers-common crun

# kubelet, k8s, cri-o, etc.. are very finnicky about the go version used to build them - if a go
# version is already installed use that one rather than the one that the ubuntu distro installs
# by default. Otherwise we might overwrite it with a wrong version or end up with mutliple versions
# installed, and the build automation for different projects might pick different ones without us
# realizing.

if command -v go > /dev/null; then
  echo go is already installed
else
  # Install manually rather than via apt because by default apt might install a version too old to
  # compile cri-o and crun.
  GO_VERSION="1.24.1"
  curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
  rm -rf /usr/local/go
  tar -C /usr/local -xzf /tmp/go.tar.gz
  rm /tmp/go.tar.gz
  ln -sf /usr/local/go/bin/go /usr/local/bin/go
  ln -sf /usr/local/go/bin/gofmt /usr/local/bin/gofmt
fi

# Take a backup of the vanilla cri-o and crun binary (and configs) that we'll modify in case we
# want to restore them. Then, overwrite the binaries and config with our custom stuff.
readonly backup_dir="default-crio-crun-backups"
readonly crio_cfg_file="/etc/crio/crio.conf.d/10-crio.conf"
readonly crio_bin="$(which crio)"
if [[ ! -d "$backup_dir" ]]; then
  mkdir "$backup_dir"
fi
if [[ ! -x "$backup_dir/crun" ]]; then
  cp "/usr/libexec/crio/crun" "$backup_dir/"
fi
if [[ ! -x "$backup_dir/crio" ]]; then
  cp "$crio_bin" "$backup_dir/"
  cp "$crio_cfg_file" "$backup_dir/"
fi

# Build crun, following instructions at https://github.com/matte21/stinglet-crun/blob/fg-cgroups/README.md
if [ -x "components/crun/crun" ]; then
  echo "custom crun has been already built, not building it again"
else
  cd components/crun
  ./autogen.sh
  ./configure
  make
  cd ../..
fi

# Build cri-o
if [ -x "components/cri-o/bin/crio" ]; then
  echo "custom cri-o has been already built, not building it again"
else
  cd "components/cri-o"
  make
  make install
  cd ../..

  # Make sure that crun is the default runtime library used by cri-o.
  sed -i 's/default_runtime = "runc"/default_runtime = "crun"/' "$crio_cfg_file"

  # Make sure that cgroupfs is the cgroup manager since it's the only one we support in
  # our custom cgroups.
  sed -i '/default_runtime = "crun"/a conmon_cgroup = "pod"' "$crio_cfg_file"
  sed -i '/conmon_cgroup = "pod"/a cgroup_manager = "cgroupfs"' "$crio_cfg_file"
fi

# Overwrite vanilla crun binary with our custom one.
cp components/crun/crun "/usr/libexec/crio/crun"

# Overwrite vanilla crio binary with our own. Actually, crun can be installed at two locations:
# /usr/local/bin/crio and /usr/bin/crio. "make install" already installs our custom one at the
# first location, but not the second one, so we manually overwrite it there.
cp components/cri-o/bin/crio "/usr/bin/crio"

echo "configured custom crun and crio to be run."
