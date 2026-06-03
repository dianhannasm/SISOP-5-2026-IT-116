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

# pindah ke folder script
cd "$(dirname "$0")"

# download kernel jika belum ada
if [ ! -f linux-6.1.1.tar.xz ]; then
    wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.1.tar.xz
fi

# extract source kernel jika belum ada foldernya
if [ ! -d linux-6.1.1 ]; then
    tar -xf linux-6.1.1.tar.xz
fi

# masuk ke source kernel
cd linux-6.1.1

# bersihkan konfigurasi lama
make mrproper

# gunakan konfigurasi default kernel
make defconfig

# compile kernel
make CC=gcc-12 HOSTCC=gcc-12 -j$(nproc) || exit 1

# salin hasil kernel ke folder output
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

# pindah ke direktori tempat script berada
cd "$(dirname "$0")"

# membuat struktur direktori root filesystem
mkdir -p rootfs/{bin,sbin,etc,proc,sys,usr/bin,usr/sbin,dev,tmp}

# menyalin binary BusyBox ke direktori /bin
cp /usr/bin/busybox rootfs/bin/

# masuk ke direktori bin
cd rootfs/bin

# membuat symlink seluruh utilitas BusyBox
# contoh: ls -> busybox, cat -> busybox, sh -> busybox
for cmd in $(./busybox --list)
do
    ln -sf busybox $cmd
done

# kembali ke root filesystem
cd ..

# membuat file init (proses pertama/PID 1 saat boot)
cat > init << 'EOF'
#!/bin/sh

# mount filesystem proc
mount -t proc proc /proc

# mount filesystem sysfs
mount -t sysfs sys /sys

# pesan ketika boot berhasil
echo "Mini Linux boot berhasil"

# menjalankan shell BusyBox
exec /bin/sh
EOF

# memberikan permission executable pada init
chmod +x init

# mengemas seluruh root filesystem menjadi initramfs
# format: cpio -> gzip -> single.gz
find . | cpio -o -H newc | gzip > ../osboot/single.gz

# notifikasi selesai
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

# menghapus filesystem lama jika ada
rm -rf multi_rootfs

# membuat direktori root filesystem
mkdir -p multi_rootfs

# masuk ke root filesystem
cd multi_rootfs

# membuat struktur direktori utama
mkdir -p bin dev proc sys etc tmp root home/{henn,hann,viii,kids}

# direktori demo FUSE
mkdir -p opt/fuse-demo

# membuat contoh program sederhana FUSE
cat > opt/fuse-demo/hello_fuse.c << 'EOF'
#include <stdio.h>

int main() {
    printf("Hello from FUSE demo\n");
    return 0;
}
EOF

# dokumentasi package FUSE
cat > opt/fuse-demo/README << 'EOF'
FUSE demonstration package

Installed via:
party install fuse

Kernel support:
CONFIG_FUSE_FS=y
EOF

# direktori konfigurasi DHCP BusyBox
mkdir -p usr/share/udhcpc

# script yang dijalankan udhcpc ketika memperoleh IP
cat > usr/share/udhcpc/default.script << 'EOF'
#!/bin/sh

# konfigurasi IP interface
ifconfig $interface $ip netmask $subnet up

# menambahkan default gateway
route add default gw $router

# mengatur DNS
echo "nameserver $dns" > /etc/resolv.conf
EOF

# membuat script dapat dieksekusi
chmod +x usr/share/udhcpc/default.script

# menyimpan username dan password
cat > etc/users << EOF
root:root123
henn:henn123
hann:hann123
viii:viii123
kids:kids123
EOF

# permission direktori sesuai spesifikasi
chmod 777 tmp

chmod 700 root

chmod 700 home/henn
chmod 750 home/hann
chmod 750 home/viii
chmod 750 home/kids

# menyalin BusyBox ke filesystem
cp /bin/busybox bin/

# masuk ke direktori bin
cd bin

# membuat symlink seluruh utilitas BusyBox
for cmd in $(./busybox --list)
do
    ln -sf busybox $cmd
done

# kembali ke root filesystem
cd ..

# membuat init (PID 1)
cat > init << 'EOF'
#!/bin/sh

# mount proc filesystem
mount -t proc none /proc

# mount sysfs
mount -t sysfs none /sys

clear

# banner awal
echo "================================="
echo "      FAREWELL PARTY"
echo "================================="
echo ""

USER=""

# proses login
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

    # cek username dan password
    while IFS=: read U P
    do
        if [ "$USER" = "$U" ] && [ "$PASS" = "$P" ]; then
            VALID=1
            break
        fi
    done < /etc/users

    # keluar jika login berhasil
    if [ "$VALID" = "1" ]; then
        break
    fi

    echo ""
    echo "Login gagal!"
    echo ""
done

clear

# banner setelah login
echo "================================="
echo "      FAREWELL PARTY"
echo "================================="
echo ""
echo "Welcome, $USER"

# konfigurasi jaringan statis untuk QEMU user networking
ifconfig eth0 up
ifconfig eth0 10.0.2.15 netmask 255.255.255.0

# default gateway QEMU
route add default gw 10.0.2.2

# DNS Google
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# menjalankan shell BusyBox
exec /bin/sh

EOF

# membuat init executable
chmod +x init

# membuat package manager sederhana bernama party
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

# memberikan permission executable
chmod +x bin/party

# mengemas filesystem menjadi initramfs
find . | cpio -H newc -ov | gzip > ../osboot/multi.gz

# kembali ke direktori awal
cd ..

# menghapus folder build sementara
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

# menghapus folder build ISO sebelumnya jika ada
rm -rf iso_root

# membuat struktur direktori yang dibutuhkan GRUB
mkdir -p iso_root/boot/grub

# menyalin kernel ke direktori boot
cp osboot/bzImage iso_root/boot/

# menyalin initramfs single user
cp osboot/single.gz iso_root/boot/

# menyalin initramfs multi user
cp osboot/multi.gz iso_root/boot/

# membuat konfigurasi GRUB
cat > iso_root/boot/grub/grub.cfg << 'EOF'

# waktu tunggu menu boot (detik)
set timeout=5

# menu default yang dipilih
set default=0

# menu boot single user
menuentry "Single User" {
    linux /boot/bzImage console=ttyS0
    initrd /boot/single.gz
}

# menu boot multi user
menuentry "Multi User" {
    linux /boot/bzImage console=ttyS0
    initrd /boot/multi.gz
}
EOF

# membuat file ISO bootable menggunakan GRUB
grub-mkrescue -o osboot/farewell.iso iso_root

# menghapus folder sementara
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

# memilih mode boot berdasarkan argumen yang diberikan
case "$1" in

# boot langsung ke single-user filesystem
--single)
qemu-system-x86_64 \
-kernel osboot/bzImage \
-initrd osboot/single.gz \
-append "console=ttyS0" \
-nographic \
-nic user
;;

# boot langsung ke multi-user filesystem
--multi)
qemu-system-x86_64 \
-kernel osboot/bzImage \
-initrd osboot/multi.gz \
-append "console=ttyS0" \
-nographic \
-nic user
;;

# boot menggunakan file ISO
--all)
qemu-system-x86_64 \
-cdrom osboot/farewell.iso \
-boot d \
-m 512 \
-nographic \
-nic user
;;

# jika argumen tidak valid
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

# membuat timestamp dengan format DDMMYYYY-HHMMSS
TIMESTAMP=$(date +"%d%m%Y-%H%M%S")

# membuat file ZIP berisi seluruh hasil build
zip "osboot/farewell_backup_${TIMESTAMP}.zip" \
    osboot/bzImage \
    osboot/single.gz \
    osboot/multi.gz \
    osboot/farewell.iso

# menghapus file hasil build setelah berhasil dibackup
rm -f osboot/bzImage
rm -f osboot/single.gz
rm -f osboot/multi.gz
rm -f osboot/farewell.iso

# notifikasi selesai
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

