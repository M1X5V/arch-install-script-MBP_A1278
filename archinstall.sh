#!/bin/bash

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Update system clock
timedatectl set-ntp true

# Partition the disk
echo "Partitioning the disk using cfdisk..."
cfdisk /dev/sda

# Format the partitions
mkfs.fat -F32 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
mkswap /dev/sda4

# Mount the partitions
mount /dev/sda2 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
mkdir /mnt/home
mount /dev/sda3 /mnt/home
swapon /dev/sda4

# Install base system and Linux kernel
pacstrap /mnt base linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system
arch-chroot /mnt <<EOF

# Set timezone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# Set localization
echo "de_DE.UTF-8 UTF-8" > /etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" > /etc/locale.conf

# Set hostname
echo "arch-macbook" > /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch-macbook.localdomain arch-macbook" >> /etc/hosts

# Set root password
echo "Setting root password..."
echo "root:123456789" | chpasswd

# Add user 'diana' with password
useradd -m -G wheel diana
echo "diana:123456789" | chpasswd

# Configure sudoers
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install essential packages
pacman -S --noconfirm grub efibootmgr networkmanager dialog wpa_supplicant base-devel linux-headers git nano vim

# Install drivers for MacBook A1278
pacman -S --noconfirm xf86-input-synaptics

# Configure and install GRUB
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Enable services
systemctl enable NetworkManager

# Install KDE Plasma
pacman -S --noconfirm plasma-meta kde-applications sddm
systemctl enable sddm

EOF

# Unmount partitions and reboot
umount -R /mnt
swapoff /dev/sda4
echo "Installation complete. Rebooting now..."
reboot