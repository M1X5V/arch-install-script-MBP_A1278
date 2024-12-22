#!/bin/bash

# Arch Linux Installation Script
# Partition Scheme: /boot, /, /home, swap
# Desktop Environment: KDE Plasma

# Set timezone, locale, and hostname
set_timezone_locale_hostname() {
  echo "Setting timezone, locale, and hostname..."
  ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
  hwclock --systohc
  sed -i 's/^#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
  locale-gen
  echo "LANG=de_DE.UTF-8" > /etc/locale.conf
  echo "HalalArch" > /etc/hostname
}

# Install base packages and KDE Plasma
install_base_kde() {
  echo "Installing base packages and KDE Plasma..."
  pacstrap /mnt base linux linux-firmware vim nano networkmanager \
    xorg xorg-server plasma-meta kde-applications-meta sddm
}

# Enable essential services
enable_services() {
  echo "Enabling services..."
  systemctl enable NetworkManager
  systemctl enable sddm
}

# Mount partitions
mount_partitions() {
  echo "Mounting partitions..."
  mount /dev/sda2 /mnt              # Mount root
  mkdir -p /mnt/boot /mnt/home
  mount /dev/sda1 /mnt/boot         # Mount boot
  mount /dev/sda3 /mnt/home         # Mount home
  swapon /dev/sda4                  # Enable swap
}

# Generate fstab and chroot
generate_fstab_and_chroot() {
  echo "Generating fstab..."
  genfstab -U /mnt >> /mnt/etc/fstab
  echo "Chrooting into the new system..."
  arch-chroot /mnt bash <<EOF
set_timezone_locale_hostname
install_base_kde
enable_services
EOF
}

# Finalize installation
finalize_installation() {
  echo "Setting root password..."
  echo "root:123456789" | chpasswd
  echo "Installation complete. You can reboot now."
}

# Main installation steps
main() {
  echo "Starting Arch Linux installation with KDE Plasma..."
  mount_partitions
  install_base_kde
  generate_fstab_and_chroot
  finalize_installation
}

main