#!/bin/bash

case "$1" in

--single)
qemu-system-x86_64 \
-kernel osboot/bzImage \
-initrd osboot/single.gz \
-append "console=ttyS0" \
-nographic \
-nic user
;;

--multi)
qemu-system-x86_64 \
-kernel osboot/bzImage \
-initrd osboot/multi.gz \
-append "console=ttyS0" \
-nographic \
-nic user
;;

--all)
qemu-system-x86_64 \
-cdrom osboot/farewell.iso \
-boot d \
-m 512 \
-nographic \
-nic user
;;

*)
echo "Usage:"
echo "./qemu.sh --single"
echo "./qemu.sh --multi"
echo "./qemu.sh --all"
;;
esac
