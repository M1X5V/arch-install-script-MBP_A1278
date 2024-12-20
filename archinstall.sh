#!/bin/bash

# Exit on errors
set -e

# Variables (edit these as needed)
HOSTNAME="arch-macbook"
USERNAME="user"
PASSWORD="password"
DISK="/dev/sda"  # Replace with your MacBook's drive (use lsblk to check)

echo "Starting Arch Linux installation on MacBook Pro A1278 with KDE and tools..."

# 1. Update system clock
echo "Updating system clock..."
timedatectl set-ntp true

# 2. Launch cfdisk for manual partitioning
echo "Launching cfdisk for partitioning..."
echo "Please partition the disk as follows:"
echo "  - 512M EFI System Partition (type: EFI System)"
echo "  - 50G Linux root partition (type: Linux root (x86-64))"
echo "  - Remaining space for /home partition (type: Linux filesystem)"
echo "  - 8G swap partition (type: Linux swap)"
echo
echo "When finished, press 'Write' in cfdisk to save changes."
read -p "Press ENTER to continue and start cfdisk..."
cfdisk "$DISK"

# 3. Confirm partitions
echo "Verifying partitions..."
lsblk "$DISK"
read -p "Are the partitions set up correctly? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
    echo "Exiting installation. Please rerun the script after correcting partitions."
    exit 1
fi

# 4. Format partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${DISK}1"  # EFI
mkfs.ext4 "${DISK}2"      # root
mkfs.ext4 "${DISK}3"      # /home
mkswap "${DISK}4"         # swap

# 5. Activate swap
echo "Activating swap..."
swapon "${DISK}4"

# 6. Mount partitions
echo "Mounting partitions..."
mount "${DISK}2" /mnt
mkdir -p /mnt/boot
mount "${DISK}1" /mnt/boot
mkdir -p /mnt/home
mount "${DISK}3" /mnt/home

# 7. Install the base system
echo "Installing base system..."
pacstrap /mnt base linux linux-firmware

# 8. Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# 9. Chroot into the new system
echo "Entering chroot environment..."
arch-chroot /mnt /bin/bash <<EOF

# 10. Set up timezone and localization
echo "Configuring time zone and localization..."
ln -sf /usr/share/zoneinfo/$(curl -s https://ipapi.co/timezone) /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 11. Set up hostname and hosts
echo "Setting hostname..."
echo "$HOSTNAME" > /etc/hostname
cat <<EOT > /etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
EOT

# 12. Set root password
echo "Setting root password..."
echo "root:$PASSWORD" | chpasswd

# 13. Create a user
echo "Creating user $USERNAME..."
useradd -m -G wheel "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
echo "%wheel ALL=(ALL) ALL" > /etc/sudoers.d/wheel

# 14. Install bootloader (systemd-boot)
echo "Installing bootloader..."
bootctl install
cat <<EOT > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=$(blkid -s PARTUUID -o value ${DISK}2) rw
EOT

cat <<EOT > /boot/loader/loader.conf
default arch
timeout 5
editor 0
EOT

# 15. Install additional packages
echo "Installing essential packages..."
pacman -Sy --noconfirm \
    base-devel \
    linux-headers \
    broadcom-wl \
    tlp \
    acpi \
    acpid \
    xorg \
    git \
    vim \
    sudo \
    mesa \
    xf86-video-intel \
    sddm \
    plasma-meta \
    kde-applications \
    dolphin \
    konsole \
    ark \
    okular \
    gcc \
    cmake \
    python \
    python-pip \
    nodejs \
    npm \
    docker \
    docker-compose

# Enable necessary services
echo "Enabling system services..."
systemctl enable sddm
systemctl enable tlp
systemctl enable acpid
systemctl enable docker

# Configure touchpad for MacBook
echo "Configuring MacBook touchpad..."
pacman -Sy --noconfirm xf86-input-synaptics
cat <<EOT > /etc/X11/xorg.conf.d/50-synaptics.conf
Section "InputClass"
    Identifier "touchpad"
    Driver "synaptics"
    MatchIsTouchpad "on"
    Option "TapButton1" "1"
    Option "TapButton2" "3"
    Option "TapButton3" "2"
    Option "VertEdgeScroll" "on"
    Option "HorizEdgeScroll" "on"
EndSection
EOT

EOF

# 16. Unmount and reboot
echo "Unmounting partitions and rebooting..."
umount -R /mnt
echo "Installation complete! Rebooting now..."
reboot
