#!/bin/bash

# 何命令失败（退出状态非0），则脚本会终止执行
set -o errexit
# 尝试使用未设置值的变量，脚本将停止执行
set -o nounset

ROOTFS=`mktemp -d`
TARGET_DEVICE=qemu
TARGET_ARCH=riscv64
COMPONENTS=main
DISKSIZE="60G"
DISKIMG="openkylin-$TARGET_DEVICE-$TARGET_ARCH.qcow2"
readarray -t REPOS < ./profiles/sources.list
PACKAGES=`cat ./profiles/packages.txt | grep -v "^-" | xargs | sed -e 's/ /,/g'`

sudo cp data/openkylin-archive-keyring.gpg /etc/apt/trusted.gpg.d
sudo apt update -y
sudo apt-get install -y qemu-user-static qemu-system binfmt-support mmdebstrap arch-test usrmerge usr-is-merged qemu-system-misc opensbi u-boot-qemu systemd-container

sudo mmdebstrap --arch=$TARGET_ARCH --variant=buildd \
        --hook-dir=/usr/share/mmdebstrap/hooks/merged-usr \
        --include=$PACKAGES \
        --customize=./profiles/stage2.sh \
        yangtze $ROOTFS\
        "${REPOS[@]}"

sudo echo "openkylin-$TARGET_ARCH-$TARGET_DEVICE" | sudo tee $ROOTFS/etc/hostname > /dev/null
sudo echo "Asia/Shanghai" | sudo tee $ROOTFS/etc/timezone > /dev/null
sudo ln -sf /usr/share/zoneinfo/Asia/Shanghai $ROOTFS/etc/localtime
sudo tee -a $ROOTFS/etc/default/u-boot <<-'EOF'
# change ro to rw, set root device
U_BOOT_PARAMETERS="rw noquiet root=/dev/vda1"

# fdt is provided by qemu
U_BOOT_FDT_DIR="noexist"
EOF

# openkylin 使用这个命令更新 u-boot 但是不会修改 /boot/extlinux/extlinux.conf 文件，使用手动编辑
#sudo systemd-nspawn -D $ROOTFS bash -c "u-boot-update || true"
sudo tee -a $ROOTFS/boot/extlinux/extlinux.conf <<-'EOF'
label l0
        menu label openkylin 1.0.1 6.6.8-riscv64
        linux /boot/vmlinux-6.6.8-riscv64
        initrd /boot/initrd.img-6.6.8-riscv64


        append  rw noquiet root=/dev/vda1
EOF
# sudo virt-make-fs --partition=gpt --type=ext4 --size=+10G --format=qcow2 $ROOTFS $DISKIMG
# sudo rm -rf $ROOTFS