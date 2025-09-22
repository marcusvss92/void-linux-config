# Void Linux Installation with BTRFS on LUKS in Lenovo LOQ RTX 2050 and iGPU Intel

## Void Live image (Void Linux Documentation - About Libs and Installation): https://docs.voidlinux.org/

## Requirements

- UEFI system
- Internet connection during installation
- At least 8GB RAM (for pentesting tools)
- 100GB+ disk space recommended

## Installation section and steps

- Prepare filesystems
- Create a new root and mount filesystems
- Base installation
- The XBPS method
- Configure filesystems
- Entering the Chroot
- Installation Configuration
- Set a Root Password\
- Installing efibootmgr
- **OPTIONAL:** LUKS Key Setup

## Configs file

- dracut.conf
- rc.conf
- fstab
- locale.conf
- libc-locales
- hostname
- 10-luks.conf
- 60-graphics.conf
- intel_ucode.conf

## Scripts

- update-efi-entry.sh
- btrfs-map-physical.c

## Introduction and Main Features

In this guide, we gonna install Void Linux step-by-step and cover the following below:

- UEFI with efibootmgr
- BTRFS filesystem with LZO compress
- System installation using the main Void Linux documentation and additional configurations
- Hyprland configuration (LATER)

- 🔐 LUKS Encryption with swapfile and hibernation support
- 🛡️ Security Hardening with kernel parameters and system configuration
- 🎯 Pentesting Tools including Metasploit, nmap, and more
- 🚀 Modern Shell with ZSH and Oh-My-Zsh optimized for security work]
- ⚡ Performance Optimization with dracut hostonly and compression
- 🔧 Development Environment with multiple programming languages

## Security Features

- Kernel Hardening: KASLR, SMAP/SMEP, stack protection
- Boot Security: Multiple boot modes (secure/pentest/compatible)
- Network Security: Firewall, fail2ban, secure sysctl settings
- File System: Proper permissions, audit logging
- User Security: doas instead of sudo, restricted shells

## Pentesting Tools Included

- Network: nmap, masscan, netcat
- Web: nikto, gobuster, sqlmap, Burp Suite setup
- Password: john, hashcat, hydra
- Wireless: aircrack-ng suite
- Framework: Metasploit Framework (compiled from source)]
- Analysis: wireshark, binwalk, foremost

## Contributing

1. Fork this repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - feel free to use and modify

## Support

- Create an issue in this repository
- Check the troubleshooting guide
- Join Void Linux community channels

- :warning:Warning:warning:: This setup includes significant system modifications. Always test in a virtual machine first and maintain backups of important data, or create an additional disk to install it (driver caddy, etc).

### Logging in

> boot into Void live USB and log in using these credentials: root:voidlinux or anon:voidlinux
> This document implies you're using the `root` user instead of the `anon` user, until the main user is created and used.

### Setting keyboard layout

  ```sh
loadkeys br-abnt2
  ```

OR

  ```sh
loadkeys us
  ```

### Connecting to the Wi-Fi router

  ```sh
cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
wpa_passphrase <ssid> <passphrase> | tee -a /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
wpa_supplicant -B -i <interface> -c /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
sv restart dhcpcd
ip link set up <interface>
  ```

### Partitioning the Drive

NOTE: Just remember that your drive might use a different name, so please check it out before executing these commands.

  ```sh
dd if=/dev/urandom of=/dev/nvme1n1 bs=1M oflag=direct status=progress 
fdisk /dev/nvme1n1
  ```

Then:
  1. Select `g` to generate a GTP table
  2. Select `n` to create the EFI partition with size of +400M
  3. Change the created partition's type by selecting `t` and then selecting the option that represents `EFI Partition`
  4. Select `n` to create the `btrfs` partition with the remaining size

OR you can use these commands below...

  ```sh
dd if=/dev/urandom of=/dev/nvmexnx bs=1M oflag=direct status=progress
xbps-install -Su xbps
xbps-install -Sy parted
parted -a optimal /dev/nvme1n1
mklabel gpt
unit mib
mkpart primary 2048s 400
set 1 esp on
mkpart primary 400 -1
quit  
  ```
 
### Creating the LUKS Partition and filesystems
  
  ```sh
cryptsetup benchmark
cryptsetup --type luks2 -c aes-xts-plain64 -h sha512 -s 512 luksFormat /dev/nvme1n1p2
crypsetup luksOpen /dev/nvme1n1p2 cryptvoid
mkfs.btrfs -L void /dev/mapper/cryptvoid
mkfs.vfat -v -n "EFI" /dev/nvmexnxp1
  ```
  
### Mounting the `btrfs` partition and creating subvolumes
  
  ```sh
BTRFS_OPTS="rw,noatime,ssd,compress=lzo,space_cache=v2,discard=async,commit=60"
mount -o $BTRFS_OPTS /dev/mapper/cryptvoid /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@usr
btrfs subvolume create /mnt/@var
btrfs subvolume create /mnt/@opt
btrfs subvolume create /mnt/@snapshots
umount /mnt
  ```
  
### Mounting the top-level partitions and creating the nested BTRFS subvolumes
  
   ```sh
mount -o $BTRFS_OPTS,subvol=@ /dev/mapper/cryptvoid /mnt
mkdir -p /mnt/{boot/efi,home,usr,var,opt,.snapshots}
mount -o $BTRFS_OPTS,subvol=@home /dev/mapper/cryptvoid /mnt/home
mount -o $BTRFS_OPTS,subvol=@usr /dev/mapper/cryptvoid /mnt/usr
mount -o $BTRFS_OPTS,subvol=@var /dev/mapper/cryptvoid /mnt/var
mount -o $BTRFS_OPTS,subvol=@opt /dev/mapper/cryptvoid /mnt/opt
mount -o $BTRFS_OPTS,subvol=@snapshots /dev/mapper/cryptvoid /mnt/.snapshots
mkdir /mnt/var/cache
btrfs subvolume create /mnt/var/cache/xbps
btrfs subvolume create /mnt/var/tmp
btrfs subvolume create /mnt/srv
mount -o rw,noatime /dev/nvme1n1p1 /mnt/boot/efi
mount | grep -E "/dev/mapper/cryptvoid|/dev/nvme1n1p1"
  ```

### Swap file creation and fstab configuration
  
  ```sh
truncate -s 0 /mnt/swapfile
chattr +C /mnt/swapfile
chmod 600 /mnt/swapfile
dd if=/dev/zero of=/mnt/swapfile bs=1G count=32 status=progress
mkswap -U clear -L SWAP --file /mnt/wapfile
swapon /mnt/swapfile
  ```
  
  ```sh
export UEFI_UUID=$(blkid -s UUID -o value /dev/nvme1n1p1)
export LUKS_UUID=$(blkid -s UUID -o value /dev/nvme1n1p2)
export ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/cryptvoid)

cat <<EOF > /mnt/etc/fstab
UUID=$UEFI_UUID /boot/efi vfat defaults,noatime 0 2
UUID=$ROOT_UUID / btrfs $BTRFS_OPTS,subvol=@ 0 1
UUID=$ROOT_UUID /home btrfs $BTRFS_OPTS,subvol=@home 0 2
UUID=$ROOT_UUID /usr btrfs $BTRFS_OPTS,subvol=@usr 0 2
UUID=$ROOT_UUID /var btrfs $BTRFS_OPTS,subvol=@var 0 2
UUID=$ROOT_UUID /opt btrfs $BTRFS_OPTS,subvol=@opt 0 2
UUID=$ROOT_UUID /.snapshots btrfs $BTRFS_OPTS,subvol=@snapshots 0 2
/swapfile none swap defaults 0 1
tmpfs /tmp tmpfs defaults,nosuid,nodev,noatime,mode=1777 0 0
EOF
  ```
  
### Installing the base system

**NOTE:** We will use Glibc for now to avoid erros and incompatibility with Metasploit and so on.

  ```sh
REPO=https://repo-default.voidlinux.org/current
ARCH=x86_64
mkdir -p /mnt/var/db/xbps/keys
cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys
XBPS_ARCH=$ARCH xbps-install -S -R "$REPO" -r /mnt base-system void-repo-nonfree linux linux-firmware linux-headers efibootmgr dracut btrfs-progs cryptsetup vim opendoas zsh zsh-completions wayland nftables 
  ```
  
### Creating the chroot and important system configuration
  
  ```sh
cp -L /etc/resolv.conf /mnt/etc/
xchroot /mnt/bash
  ```

  ```sh
chroot /mnt /bin/bash

passwd root
chsh -s /bin/bash root

useradd -m -G wheel,audio,video,input,storage,optical,scanner mvinicius
passwd mvinicius

groupadd wireshark
groupadd netdev
useradd -m -G wheel,wireshark,dialout,netdev -s $(which zsh) pentester
passwd pentester

useradd -m -s /bin/bash sandbox

groupadd docker
groupadd vboxusers
useradd -m -G wheel,docker,vboxusers developer

echo void.local > /etc/hostname

cat <<EOF > /etc/rc.conf
# /etc/rc.conf - system configuration for void

HOSTNAME="void.local"
HARDWARECLOCK="UTC"
TIMEZONE="America/Sao_Paulo"
KEYMAP="br-abnt2"
EOF

echo LANG=en_US.UTF-8 > /etc/locale.conf
echo 'en_US.UTF-8 UTF-8' > /etc/default/libc-locales
xbps-reconfigure -f glibc-locales
ls /usr/share/zoneinfo
ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
  ```

### Dracut configuration

  ```sh
cat << EOF > /etc/dracut.conf
# PUT YOUR CONFIG IN separate files
# in /etc/dracut.conf.d named "<name>.conf"
# SEE man dracut.conf(5) for options
hostonly="yes"
hostonly_mode="sloppy"	# or strict
compress="gzip"
use_fstab="yes"
tmpdir=/tmp
EOF
  ```

  ```sh
cat << EOF > /etc/dracut.conf.d/10-luks.conf
add_dracutmodules+=" crypt dm btrfs resume "
omit_dracutmodules=" systemd systemd-initrd dracut-systemd systemd-udevd "
install_items+=" /etc/crypttab /etc/fstab "
kernel_cmdline+=" rd.luks.uuid=$LUKS_UUID rd.luks.allow-discards root=UUID=$ROOT_UUID rootfstype=btrfs rw "
filesystems+=" btrfs vfat "
EOF
  ```

  ```sh
cat << EOF > /etc/dracut.conf.d/60-graphics.conf
# Essential video modules
add_drivers+=" nvidia nvidia_modeset nvidia_uvm nvidia_drm "
add_drivers+=" i915 "

# Replicating the NVIDIA bootloader configuration for compatibility
kernel_cmdline+=" nvidia-drm.modeset=1 nvidia-drm.fbdev=1 nvidia.NVreg_OpenRmEnableUnsupportedGpus=1 "

# Install necessary firmwares
install_items+=" /lib/firmware/i915/* "
EOF
  ```

  ```sh
cat << EOF > /etc/dracut.conf.d/intel_ucode.conf
early_microcode="yes"
EOF
  ```

### Network and session management configuration

  ```sh
cat <<EOF > /etc/hosts
#
# /etc/hosts: static lookup table for host names
#
127.0.0.1   localhost
::1         localhost
127.0.0.1   void.localdomain void
EOF
  ```

  ```sh
xbps-install -S NetworkManager elogind
doas ln -s /etc/sv/NetworkManager /var/service
doas ln -s /etc/sv/dbus /var/service
doas ln -s /etc/sv/elogind /var/service
  ```

### Bootloader configuration
  
  ```sh
efibootmgr --create \
--disk /dev/sda \
--part 1 \
--label "Void Linux Hardened" \
--loader /vmlinuz-$(uname -r) \
--unicode "root=UUID=$ROOT_UUID rootfstype=btrfs initrd=\\initramfs-$(uname -r).img"
efibootmgr --create \
--disk /dev/nvme1n1 \
--part 1 \
--label "Void Linux" \
--loader /vmlinuz-$(uname -r) \
--unicode "rd.luks.uuid=$LUKS_UUID rd.luks.allow-discards root=UUID=$ROOT_UUID rootfstype=btrfs rw initrd=\\initramfs-$(uname -r).img nvidia-drm.modeset=1 nvidia-drm.fbdev=1 nvidia.NVreg_OpenRmEnableUnsupportedGpus=1 quiet loglevel=3"
  ```

### Unmounting mountpoint

  ```sh
exit
exit
umount -R /mnt
reboot
  ```

## Post-installation

### Install NVIDIA video driver and configure it (:warning:FOR REVISION:warning:)
  
  ```sh
doas xbps-install -Sy mesa mesa-dri mesa-vaapi mesa-vdpau mesa-vulkan-intel vdpauinfo nvidia nvidia-firmware nvidia-dkms nvidia-opencl nvidia-gtklibs nvidia-libs nvidia-vaapi-driver libvdpau libva-glx libva-utils vulkan vulkan-loader Vulkan-Headers Vulkan-Tools Vulkan-Utility-LIbraries Vulkan-ValidationLayers gstreamer1 gstreamer-vaapi primus bbswitch bumblebee nvtop
doas ln -s /etc/sv/nvidia-powerd /var/service
nvidia-smi
  ```

  ```sh
doas tee /usr/local/bin/nvidia-run << 'EOF'
#!/bin/bash
# Wrapper to run applications in NVIDIA and power off the GPU after

if [ $# -eq 0 ]; then
    echo "Usage: nvidia-run <command> [arguments...]"
    exit 1
fi

# Power on the GPU NVIDIA via bbswitch
if [ -w /proc/acpi/bbswitch ]; then
    echo ON | doas tee /proc/acpi/bbswitch > /dev/null
fi

# Set up the PRIME Render Offload variables
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only

# For OpenGL programs, use primusrun if available
if command -v primusrun >/dev/null 2>&1; then
    primusrun "$@"
else
    "$@"
fi

RET=$?

# Power off the GPU NVIDIA after closing a program
if [ -w /proc/acpi/bbswitch ]; then
    echo OFF | doas tee /proc/acpi/bbswitch > /dev/null
fi

exit $RET
EOF
  ```

### Security configuration

#### Locking the root account
:warning: **Important** :warning:  
Only run this after setting up the main user!

  ```sh
doas passwd -dl root
  ```

  ```sh
doas xbps-install -Sy nftables
doas /usr/local/bin/basic-firewall.sh
doas nft list ruleset > /etc/nftables.conf
doas ln -s /etc/sv/nftables /var/service/
doas sv start nftables
  ```

  ```sh(:warning:FOR REVISION:warning:)
auditd
  ```

  ```sh(:warning:FOR REVISION:warning:)
fail2ban
  ```

  ```sh(:warning:FOR REVISION:warning:)
aide
  ```

### Others configurations (:warning:FOR REVISION:warning:)
  
  ```sh
truncate -s 2M keyfile.bin # OR dd bs=515 count=4 if=/dev/urandom of=/boot/keyfile.bin
cryptsetup -v luksAddKey /dev/sdX2 /boot/keyfile.bin
chmod 000 /boot/keyfile.bin
chmod -R g-rwx,o-rwx /boot
cat <<EOF >> /etc/crypttab
cryptvoid UUID=$LUKS_UUID /boot/keyfile.bin luks
EOF
  
echo 'install_items+=" /boot/keyfile.bin /etc/crypttab "' > /etc/dracut.conf.d/10-crypt.conf
ln -s /etc/sv/dhc /etc/runit/runsvdir/default
# OR
<USE-MKINITCPIO>
  ```
    
### Step 4 - Exit and Reboot

  ```sh
exit
reboot
  ```

# References (:warning:FOR REVISION:warning:)





### OPTIONAL: LUKS Key Setup (:warning:FOR REVISION:warning:)

And now to avoid having to enter the password twice on boot, a key will be configured to automatically unlock the encrypted volume on boot. First, generate a random key.

  ```sh
[xchroot /mnt] # dd bs=1 count=64 if=/dev/urandom of=/boot/volume.key
64+0 records in
64+0 records out
64 bytes copied, 0.000662757 s, 96.6 kB/s
  ```

Next, add the key to the encrypted volume.

  ```sh
[xchroot /mnt] # cryptsetup luksAddKey /dev/sda1 /boot/volume.key
Enter any existing passphrase:
  ```

Change the permissions to protect the generated key.

  ```sh
[xchroot /mnt] # chmod 000 /boot/volume.key
[xchroot /mnt] # chmod -R g-rwx,o-rwx /boot
  ```

This keyfile also needs to be added to /etc/crypttab. Again, this will be /dev/sda2 on EFI systems.

  ```sh
voidvm   /dev/sda1   /boot/volume.key   luks
  ```

And then the keyfile and crypttab need to be included in the initramfs. Create a new file at /etc/dracut.conf.d/10-crypt.conf with the following line:

  ```sh
install_items+=" /boot/volume.key /etc/crypttab "
  ```
