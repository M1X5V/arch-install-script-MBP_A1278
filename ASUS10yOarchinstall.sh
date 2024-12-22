#!/bin/bash

# Arch Linux Installation Script
# Partition Scheme: /boot, /, /home, swap
# Desktop Environment: KDE Plasma
# User: Diana (Password: 123456789)
# Language: German

# Mount partitions
mount_partitions() {
  echo "Mounting partitions..."
  mount /dev/sda2 /mnt              # Mount root
  mkdir -p /mnt/boot /mnt/home
  mount /dev/sda1 /mnt/boot         # Mount boot
  mount /dev/sda3 /mnt/home         # Mount home
  swapon /dev/sda4                  # Enable swap
}

# Install base packages and KDE Plasma
install_base_system() {
  echo "Installing base system and KDE Plasma..."
  pacstrap /mnt base linux linux-firmware vim nano networkmanager \
    xorg xorg-server plasma-meta kde-applications-meta sddm
}

# Generate fstab
generate_fstab() {
  echo "Generating fstab..."
  genfstab -U /mnt >> /mnt/etc/fstab
}

# Configure the system
configure_system() {
  echo "Configuring system settings..."

  # Set timezone
  ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
  hwclock --systohc

  # Set locale
  sed -i 's/^#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
  sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen  # Optional English fallback
  locale-gen
  echo "LANG=de_DE.UTF-8" > /etc/locale.conf

  # Set hostname
  echo "arch-laptop" > /etc/hostname
  echo "127.0.0.1   localhost" >> /etc/hosts
  echo "::1         localhost" >> /etc/hosts
  echo "127.0.1.1   arch-laptop.localdomain arch-laptop" >> /etc/hosts
}

# Configure users
configure_users() {
  echo "Configuring root and user accounts..."
  echo "root:123456789" | chpasswd                      # Set root password
  useradd -m -G wheel -s /bin/bash Diana               # Create user Diana
  echo "Diana:123456789" | chpasswd                    # Set password for Diana
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
}

# Enable services
enable_services() {
  echo "Enabling essential services..."
  systemctl enable NetworkManager
  systemctl enable sddm
}

# Final steps in chroot
chroot_configure() {
  arch-chroot /mnt /bin/bash <<EOF
configure_system
configure_users
enable_services
EOF
}

# Finalize installation
finalize_installation() {
  echo "Installation complete! You can reboot now."
}

# Main installation steps
main() {
  echo "Starting Arch Linux installation with KDE Plasma..."
  mount_partitions
  install_base_system
  generate_fstab
  chroot_configure
  finalize_installation
}

main