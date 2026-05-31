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
