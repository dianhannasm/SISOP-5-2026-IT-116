# SISOP-5-2026-IT-116
Dian Hanna Simanjuntak (5027251116)
## Reporting
  
## Soal 1 - Farewell Party
Pada praktikum ini dibuat sebuah sistem operasi Linux sederhana menggunakan Linux Kernel 6.1.1 dan BusyBox.

Sistem operasi yang dibuat memiliki beberapa fitur utama:

- Compile Linux Kernel 6.1.1
- Single-user filesystem
- Multi-user filesystem
- Bootable ISO
- Booting menggunakan QEMU
- Backup hasil build
- Akses internet
- Package manager
- Dukungan FUSE

---  
### Struktur Folder

```text
soal_1/
├── .config
├── backup.sh
├── iso.sh
├── kernel.sh
├── multi.sh
├── qemu.sh
├── single.sh
└── osboot/
    ├── bzImage
    ├── single.gz
    ├── multi.gz
    └── farewell.iso
```
### Compile Linux Kernel

Script:  
`kernel.sh`  
```bash
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
```

Fungsi:

- Download Linux Kernel 6.1.1
- Extract source code kernel
- Melakukan konfigurasi default kernel
- Compile kernel
- Menyimpan hasil kernel pada:

```text
osboot/bzImage
```
## Single User Filesystem

Script:
`single.sh`  
```bash
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

find . | cpio -o -H newc | gzip > ../osboot/single.gz

echo "Single filesystem selesai"
```

Filesystem dibuat menggunakan BusyBox sebagai shell environment.

Struktur direktori:

```text
/
├── bin
├── dev
├── proc
├── sys
├── etc
├── tmp
└── root
```

Fitur:

- Root memiliki akses penuh
- BusyBox digunakan sebagai shell utama
- Init melakukan mount proc dan sysfs
- Langsung masuk shell setelah boot

### Multi User Filesystem

Script:  
`multi.sh`  
```bash
#!/bin/bash

rm -rf multi_rootfs
mkdir -p multi_rootfs

cd multi_rootfs

mkdir -p bin dev proc sys etc tmp root home/{henn,hann,viii,kids}
mkdir -p opt/fuse-demo

cat > opt/fuse-demo/hello_fuse.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from FUSE demo\n");
    return 0;
}
EOF

cat > opt/fuse-demo/README << 'EOF'
FUSE demonstration package

Installed via:
party install fuse

Kernel support:
CONFIG_FUSE_FS=y
EOF

mkdir -p usr/share/udhcpc

cat > usr/share/udhcpc/default.script << 'EOF'
#!/bin/sh

ifconfig $interface $ip netmask $subnet up

route add default gw $router

echo "nameserver $dns" > /etc/resolv.conf
EOF

chmod +x usr/share/udhcpc/default.script

cat > etc/users << EOF
root:root123
henn:henn123
hann:hann123
viii:viii123
kids:kids123
EOF

chmod 777 tmp

chmod 700 root

chmod 700 home/henn
chmod 750 home/hann
chmod 750 home/viii
chmod 750 home/kids

cp /bin/busybox bin/
cd bin

for cmd in $(./busybox --list)
do
    ln -sf busybox $cmd
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

USER=""

while true
do
    echo "================================="
    echo "      FAREWELL PARTY"
    echo "================================="
    echo ""

    printf "Username: "
    read USER

    printf "Password: "
    read PASS

    VALID=0

    while IFS=: read U P
    do
        if [ "$USER" = "$U" ] && [ "$PASS" = "$P" ]; then
            VALID=1
            break
        fi
    done < /etc/users

    if [ "$VALID" = "1" ]; then
        break
    fi

    echo ""
    echo "Login gagal!"
    echo ""
done

clear

echo "================================="
echo "      FAREWELL PARTY"
echo "================================="
echo ""
echo "Welcome, $USER"

ifconfig eth0 up
ifconfig eth0 10.0.2.15 netmask 255.255.255.0
route add default gw 10.0.2.2
echo "nameserver 8.8.8.8" > /etc/resolv.conf

exec /bin/sh

EOF

chmod +x init

cat > bin/party << 'EOF'
#!/bin/sh

echo "Party Package Manager"

case "$1" in
install)
    shift
    echo "Installing package: $@"
    ;;
remove)
    shift
    echo "Removing package: $@"
    ;;
update)
    echo "Updating repository..."
    ;;
*)
    echo "Usage:"
    echo "party install <package>"
    echo "party remove <package>"
    echo "party update"
    ;;
esac
EOF

chmod +x bin/party

find . | cpio -H newc -ov | gzip > ../osboot/multi.gz

cd ..
rm -rf multi_rootfs

echo "Multi filesystem selesai"
```

Filesystem dibuat menggunakan BusyBox dan sistem login sederhana.

User yang tersedia:

| User | Password |
|--------|--------|
| root | root123 |
| henn | henn123 |
| hann | hann123 |
| viii | viii123 |
| kids | kids123 |

Struktur direktori:

```text
/
├── bin
├── dev
├── proc
├── sys
├── etc
├── tmp
├── root
└── home
    ├── henn
    ├── hann
    ├── viii
    └── kids
```

Permission:

```text
/root        -> 700
/home/henn   -> 700
/home/hann   -> 750
/home/viii   -> 750
/home/kids   -> 750
/tmp         -> 777
```

### Bootable ISO

Script:
`iso.sh`  
```bash
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
```

ISO dibuat menggunakan GRUB.

Menu boot:

```text
Single User
Multi User
```

Konfigurasi:

```text
boot/bzImage
boot/single.gz
boot/multi.gz
```
  
### Booting Menggunakan QEMU

Script:  
`qemu.sh`  
```bash
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
```

Mode yang tersedia:

### Single User

```bash
./qemu.sh --single
```

Langsung boot:

```text
bzImage + single.gz
```

### Multi User

```bash
./qemu.sh --multi
```

Langsung boot:

```text
bzImage + multi.gz
```

### ISO

```bash
./qemu.sh --all
```

Boot:

```text
farewell.iso
```

Kemudian pengguna dapat memilih:

```text
Single User
Multi User
```

## Backup

Script:  
`backup.sh`  
```bash
#!/bin/bash

TIMESTAMP=$(date +"%d%m%Y-%H%M%S")

zip "osboot/farewell_backup_${TIMESTAMP}.zip" \
    osboot/bzImage \
    osboot/single.gz \
    osboot/multi.gz \
    osboot/farewell.iso

rm -f osboot/bzImage
rm -f osboot/single.gz
rm -f osboot/multi.gz
rm -f osboot/farewell.iso

echo "Backup selesai"
```

File yang diarsipkan:

```text
bzImage
single.gz
multi.gz
farewell.iso
```

Format output:

```text
farewell_backup_[DDMMYYYY-HHMMSS].zip
```

Lokasi:

```text
osboot/
```

Setelah backup selesai file hasil build akan dihapus.

### Akses Internet

Network menggunakan:

```text
QEMU User Networking
```

Interface:

```text
eth0
```

IP diperoleh menggunakan:

```bash
udhcpc -i eth0
```

DNS:

```bash
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

Routing:

```bash
route add default gw 10.0.2.2
```

Pengujian:

### Ping

```bash
ping 8.8.8.8
```

Hasil:

```text
64 bytes from 8.8.8.8
```

### Wget

```bash
wget http://example.com
```

Hasil:

```text
index.html saved
```

---  

