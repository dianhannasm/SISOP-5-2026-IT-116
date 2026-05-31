#!/bin/bash

cd "$(dirname "$0")"

if [ ! -f linux-6.1.1.tar.xz ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.1.tar.xz
fi

if [ ! -d linux-6.1.1 ]; then
    tar -xf linux-6.1.1.tar.xz
fi

cd linux-6.1.1

make mrproper
make defconfig

scripts/config --enable CONFIG_FUSE_FS

make olddefconfig

make CC=gcc-12 HOSTCC=gcc-12 -j$(nproc) || exit 1

cp arch/x86/boot/bzImage ../osboot/bzImage || exit 1

echo "Kernel berhasil dibuat"

