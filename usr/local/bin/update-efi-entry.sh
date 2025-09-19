#!/bin/bash
# Final version with all options discussed

KERNEL_VERSION=$(uname -r)
ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/voidlinux-root 2>/dev/null || blkid -s UUID -o value $(findmnt -n -o SOURCE /))

# Security flag configurations
HARDENING_FLAGS_FULL="slab_nomerge init_on_alloc=1 init_on_free=1 page_alloc.shuffle=1 pti=on vsyscall=none debugfs=off oops=panic lockdown=confidentiality mce=0 slub_debug=P page_poison=1"
HARDENING_FLAGS_MINIMAL="pti=on vsyscall=none"

# Specific parameteres for Lenovo LOQ + RTX 2050 + Wayland
GRAPHICS_PARAMS="nvidia-drm.modeset=1 nvidia-drm.fbdev=1 nvidia.NVreg_PreserveVideoMemoryAllocations=1"

# For better hybrid support
GRAPHICS_PARAMS+=" i915.force_probe=* i915.enable_psr=0"

# NVIDIA flags
NVIDIA_FLAGS="nvidia_drm.modeset=1"

# No flags
NO_FLAGS=""

# Exemplo de entrada EFI atualizada:
#efibootmgr --create \
#    --disk /dev/sda \
#    --part 1 \
#    --label "Void Linux Wayland" \
#    --loader /vmlinuz-${KERNEL_VERSION} \
#    --unicode "root=UUID=${ROOT_UUID} ro ${HARDENING_FLAGS} ${GRAPHICS_PARAMS} ${HIBERNATION_PARAMS} initrd=\\initramfs-${KERNEL_VERSION}.img"

# Check for hibernation configuration
HIBERNATION_PARAMS=""
if [[ -f /etc/resume-offset.conf ]]; then
    source /etc/resume-offset.conf
    HIBERNATION_PARAMS="resume=UUID=${ROOT_UUID} resume_offset=${RESUME_OFFSET}"
fi

regenerate_initramfs() {
    echo "Regenerating initramfs..."
    doas dracut --force /boot/initramfs-${KERNEL_VERSION}.img ${KERNEL_VERSION}
}

create_all_entries() {
    # Remove old entries
    OLD_ENTRIES=$(efibootmgr | grep "Void Linux" | cut -c 5-8)
    for entry in $OLD_ENTRIES; do
        doas efibootmgr -B -b $entry 2>/dev/null
    done

    # Entry 1: Maximum Security
    echo "Creating SECURE entry..."
    doas efibootmgr --create \
        --disk /dev/sda \
        --part 1 \
        --label "Void Linux Secure" \
        --loader /vmlinuz-${KERNEL_VERSION} \
        --unicode "root=UUID=${ROOT_UUID} ro quiet ${HARDENING_FLAGS_FULL} ${GRAPHICS_PARAMS} ${HIBERNATION_PARAMS} initrd=\\initramfs-${KERNEL_VERSION}.img"

    # Entry 2: Pentesting Compatible
    echo "Creating PENTEST entry..."
    doas efibootmgr --create \
        --disk /dev/sda \
        --part 1 \
        --label "Void Linux Pentest" \
        --loader /vmlinuz-${KERNEL_VERSION} \
        --unicode "root=UUID=${ROOT_UUID} ro quiet ${HARDENING_FLAGS_MINIMAL} ${GRAPHICS_PARAMS} ${HIBERNATION_PARAMS} initrd=\\initramfs-${KERNEL_VERSION}.img"

    # Entry 3: Maximum Compatibility
    echo "Creating COMPATIBLE entry..."
    doas efibootmgr --create \
        --disk /dev/sda \
        --part 1 \
        --label "Void Linux Compatible" \
        --loader /vmlinuz-${KERNEL_VERSION} \
        --unicode "root=UUID=${ROOT_UUID} ro quiet ${GRAPHICS_PARAMS} ${HIBERNATION_PARAMS} initrd=\\initramfs-${KERNEL_VERSION}.img"

    echo "All EFI entries created:"
    efibootmgr | grep "Void Linux"
}

# Execute
regenerate_initramfs
create_all_entries

echo "✅ EFI entries updated successfully!"
