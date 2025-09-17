# Void Linux Installation with BTRFS and LUKS for Pentesting

## Void Live image (NOTE: [url-void-linux-documentation-about-libs-and-installation]

### Logging in

> boot into Void live USB and log in using these credentials: root:voidlinux or anon:voidlinux
> This document implies you're using the `root` user instead of the `anon` user, until the main user is created and used.

### Setting keyboard layout

```sh
loadkeys $(ls /usr/share/kbd/keymaps/i386/**/*.map.gz | grep br-abnt2)
```

OR

```sh
loadkeys $(ls /usr/share/kbd/keymaps/i386/**/*.map.gz | grep us)
```

### Connecting to the Wi-Fi router

```sh
cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
wpa_passphrase <ssid> <passphrase> | tee -a /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
sv restart dhcpcd
ip link set up <interface>
```

OR

```sh
  cp /etc/wpa_supplicant/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
  wpa_passphrase <SSID> <password> >> /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
  wpa_supplicant -B -i <interface> -c /etc/wpa_supplicant/wpa_supplicant-<interface>.conf
```

### Partitioning the Drive

NOTE: Just remember that your drive might use a different name, so please check it out before executing these commands.

  ```sh
  dd if=/dev/urandom of=/dev/nvmexn1 bs=1M oflag=direct status=progress 
  fdisk /dev/nvmexn1
  ```

Then:
  1. Select `g` to generate a GTP table
  2. Select `n` to create the EFI partition with size of +400M
  3. Change the created partition's type by selecting `t` and then selecting the option that represents `EFI Partition`
  4. Select `n` to create the `btrfs` partition with the remaining size

OR you can use these commands below...

  ```sh
  dd if=/dev/urandom of=/dev/nvmexnx bs=1M oflag=direct status=progress
  parted -a optimal /dev/nvmexn1
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
  cryptsetup --type luks2 --crypt aes-xts-plain64 --hash sha512 --key-size 512 luksFormat /dev/nvmexnxp2
  crypsetup luksOpen /dev/nvmexnxp2 cryptvoid
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
  mount -o rw,noatime /dev/nvmexnxp1 /mnt/boot/efi
  mount | grep -E "/dev/mapper/cryptvoid|/dev/nvmexnxp1"
  ```
  
### Swap file creation
  
  ```sh
  truncate -s 0 /mnt/swapfile
  chattr +C /mnt/swapfile
  btrfs property set /mnt/swapfile compression none
  chmod 600 /mnt/swapfile
  dd if=/dev/zero of=/mnt/swapfile bs=1G count=16 status=progress
  mkswap -U clear -L SWAP --file /mnt/wapfile
  swapon /mnt/swapfile
  ```
  
### Installing the base system

NOTE: This installation is for pentesting, so I will use Glibc for now.

  ```sh
  REPO=https://repo-default.voidlinux.org/current
  ARCH=x86_64
  mkdir -p /mnt/var/db/xbps/keys
  cp /var/db/xbps/keys/* /mnt/var/db/xbps/keys
  XBPS_ARCH=$ARCH xbps-install -S -R "$REPO" -r /mnt void-repo-nonfree base-system linux linux-firmware dracut btrfs-progs cryptsetup vim intel-ucode doas zsh zsh-completions NetworkManager
  ```
  
### Creating the chroot and important system configuration
  
  ```sh
  mount -t proc proc /mnt/proc
  mount -t sysfs sys /mnt/sys
  mount -o bind /dev /mnt/dev
  cp -L /etc/resolv.conf /mnt/etc
  chroot /mnt /bin/bash

  passwd root
  chsh -s /bin/bash root
  useradd mvinicius
  usermod -aG wheel,audio,video -s $(which bash) mvinicius
  passwd mvinicius

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

  cat <<EOF > /etc/hosts
  #
  # /etc/hosts: static lookup table for host names
  #
  127.0.0.1   localhost
  ::1         localhost
  127.0.0.1   void.localdomain void
  EOF

  UEFI_UUID=$(blkid -s UUID -o value /dev/nvme0nxp1)
  LUKS_UUID=$(blkid -s UUID -o value /dev/nvme0nxp2)
  ROOT_UUID=$(blkid -s UUID -o value /dev/mapper/cryptvoid)
  
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

  echo 'add_dracutmodules+="crypt btrfs resume"' >> /etc/dracut.conf
  echo 'tmpdir=/tmp' >> /etc/dracut.conf
  echo 'early_microcode="yes" >> /etc/dracut.conf.d/intel_ucode.conf
  dracut --force --hostonly --kver <kernel-version>
  dracut --force /boot/initramfs-$(uname -r).img $(uname -r)
  ```

  OPTIONAL:
  ```sh
  cp /etc/wpa_supplicant/wpa_supplicant-<interface>.conf /mnt/etc/wpa_supplicant/
  ```

### Bootloader configuration
  
  ```sh
  efibootmgr --create \
  --disk /dev/sda \
  --part 1 \
  --label "Void Linux Hardened" \
  --loader /vmlinuz-$(uname -r) \
  --unicode "root=/dev/mapper/cryptvoid initrd=\\initramfs-$(uname -r).img"
  ```

## Post-installation

### Network configuration

OPTIONAL: Run the proper `wpa_supplicant` steps to set Wi-Fi or stuff you need. Then, register and start the needed services:
```sh
doas ln -s /etc/sv/dhcpcd /var/service/
doas ln -s /etc/sv/wpa_supplicant /var/service/
```

OR

```sh
doas ln -s /etc/sv/NetworkManager /var/service
```
  
### Security configuration

#### Locking the root account
:warning: **Important** :warning:  
Only run this after setting up the main user!
  ```sh
  sudo passwd -dl root
  ```



  
  ```
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
    
### Step 2 - Install software/programs/tools
  
  ```
  xbps-install <list-of-desired-programs>
  ```
    
### Step 3 - Link services
  
  ```
  xbps-install NetworkManager
  ln -s /etc/sv/NetworkManager /var/service
  xbps-reconfigure -fa
  ```
    
### Step 4 - Exit and Reboot

  ```
  exit
  reboot
  ```

# References

Hyprland Void Dots: https://github.com/void-land/hyprland-void-dots
