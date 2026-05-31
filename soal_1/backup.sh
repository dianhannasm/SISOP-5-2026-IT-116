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
