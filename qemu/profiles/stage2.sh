#!/bin/sh

set -eu

if [ "${MMDEBSTRAP_VERBOSITY:-1}" -ge 3 ]; then
        set -x
fi

rootdir="$1"

systemd-nspawn -D $rootdir bash -c "(useradd -m -g users openkylin || true) && (usermod -a -G sudo openkylin || true)"

systemd-nspawn -D $rootdir bash -c "chsh -s /bin/bash openkylin || true"

systemd-nspawn -D $rootdir bash -c "(echo root:openkylin | chpasswd) || true"
systemd-nspawn -D $rootdir bash -c "(echo openkylin:openkylin | chpasswd) || true"
