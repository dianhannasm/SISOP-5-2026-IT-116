#!/bin/bash

cd "$(dirname "$0")"

mkdir -p rootfs/{bin,sbin,etc,proc,sys,usr/bin,usr/sbin,dev,tmp}

cp /usr/bin/busybox rootfs/bin/

cd rootfs/bin

for cmd in $(./busybox --list)
do
    ln -sf busybox $cmd
done

cd ..

cat > init << 'EOF'
#!/bin/sh

mount -t proc proc /proc
mount -t sysfs sys /sys

echo "Mini Linux boot berhasil"

exec /bin/sh
EOF

chmod +x init

find . | cpio -o -H newc | gzip > ../osboot/initramfs.cpio.gz

echo "Single filesystem selesai"
