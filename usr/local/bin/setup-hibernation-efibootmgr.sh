#!/bin/bash
# /usr/local/bin/setup-hibernation-efibootmgr.sh

# Carregar configurações
source /etc/resume-offset.conf 2>/dev/null || {
    echo "❌ Execute get-resume-offset.sh primeiro!"
    exit 1
}

KERNEL_VERSION=$(uname -r)
ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/voidlinux-root)
SWAPFILE_DEVICE_UUID=$(findmnt -no UUID -T /swapfile)

echo "=== Configuração de Hibernação ==="
echo "Root UUID: $ROOT_UUID"  
echo "Swapfile Device UUID: $SWAPFILE_DEVICE_UUID"
echo "Resume Offset: $RESUME_OFFSET"

# Remover entradas antigas
OLD_ENTRIES=$(efibootmgr | grep "Void Linux" | cut -c 5-8)
for entry in $OLD_ENTRIES; do
    efibootmgr -B -b $entry 2>/dev/null
done

# Criar entrada com hibernação
efibootmgr --create \
    --disk /dev/sda \
    --part 1 \
    --label "Void Linux Hibernation" \
    --loader /vmlinuz-${KERNEL_VERSION} \
    --unicode "root=UUID=${ROOT_UUID} ro resume=UUID=${SWAPFILE_DEVICE_UUID} resume_offset=${RESUME_OFFSET} ${HARDENING_FLAGS:-} initrd=\\initramfs-${KERNEL_VERSION}.img"

echo "✅ Entrada EFI criada com suporte à hibernação!"
