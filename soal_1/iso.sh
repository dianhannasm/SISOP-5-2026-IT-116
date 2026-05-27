#!/bin/bash

rm -rf iso_root
mkdir -p iso_root/boot/grub

cp osboot/bzImage iso_root/boot/
cp osboot/single.gz iso_root/boot/
cp osboot/multi.gz iso_root/boot/

cat > iso_root/boot/grub/grub.cfg << 'EOF'
set timeout=5
set default=0

menuentry "Single User" {
    linux /boot/bzImage console=ttyS0
    initrd /boot/single.gz
}

menuentry "Multi User" {
    linux /boot/bzImage console=ttyS0
    initrd /boot/multi.gz
}
EOF

grub-mkrescue -o osboot/farewell.iso iso_root

rm -rf iso_root

echo "ISO selesai dibuat"

