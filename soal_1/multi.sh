#!/bin/bash

rm -rf multi_rootfs
mkdir -p multi_rootfs

cd multi_rootfs

mkdir -p bin dev proc sys etc tmp root home/{henn,hann,viii,kids}

chmod 777 tmp

chmod 700 root

chmod 700 home/henn
chmod 750 home/hann
chmod 750 home/viii
chmod 750 home/kids

cp /bin/busybox bin/
cd bin

for cmd in sh ls cat echo mount uname clear login chmod chown pwd mkdir touch
do
    ln -s busybox $cmd
done

cd ..

cat > init << 'EOF'
#!/bin/sh

mount -t proc none /proc
mount -t sysfs none /sys

clear

echo "================================="
echo "      FAREWELL PARTY"
echo "================================="
echo ""

echo "Welcome, root"

exec /bin/sh
EOF

chmod +x init

find . | cpio -H newc -ov | gzip > ../osboot/multi.gz

cd ..
rm -rf multi_rootfs

echo "Multi filesystem selesai"
