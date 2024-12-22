#!/bin/bash

# Exit if any command fails
set -e

echo "Starting Arch Linux installation with 4 partitions..."

# Variables
DISK="/dev/sda" # Change if your primary disk is different
HOSTNAME="HalalArch"
USERNAME="Halal" # Replace with your desired username
PASSWORD="123456789" # Replace with your desired password

# 1. Partition the Disk using cfdisk
echo "Partitioning the disk..."
cfdisk $DISK

# Recommended Partition Layout:
# 1. /dev/sda1 -> Boot Partition (1GB, ext4)
# 2. /dev/sda2 -> Swap Partition (2GB or 2x your RAM)
# 3. /dev/sda3 -> Root Partition (50GB or as needed, ext4)
# 4. /dev/sda4 -> Home Partition (remaining space, ext4)

# 2. Format Partitions
echo "Formatting partitions..."
mkfs.ext4 ${DISK}1     # Boot partition
mkswap ${DISK}2        # Swap partition
swapon ${DISK}2
mkfs.ext4 ${DISK}3     # Root partition
mkfs.ext4 ${DISK}4     # Home partition

# 3. Mount Partitions
echo "Mounting partitions..."
mount ${DISK}3 /mnt
mkdir /mnt/boot
mount ${DISK}1 /mnt/boot
mkdir /mnt/home
mount ${DISK}4 /mnt/home

# 4. Install Essential Packages
echo "Installing base system..."
pacstrap /mnt base linux linux-firmware grub vim networkmanager

# 5. Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# 6. Chroot into the new system
echo "Chrooting into the new system..."
arch-chroot /mnt /bin/bash <<EOF
# Set timezone
ln -sf /usr/share/zoneinfo/$(curl -s https://ipapi.co/timezone) /etc/localtime
hwclock --systohc

# Set locale
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set hostname
echo "$HOSTNAME" > /etc/hostname

# Hosts file
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $HOSTNAME.localdomain $HOSTNAME" >> /etc/hosts

# Set root password
echo "root:$PASSWORD" | chpasswd

# Create a new user