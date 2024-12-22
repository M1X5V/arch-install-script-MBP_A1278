#!/bin/bash

# Arch Linux Installation Script with KDE Plasma
# User: user, Password: 123456789
# Hostname: Asus
# Partitions:
# - /dev/sda1: 1G (boot)
# - /dev/sda2: 25G (root)
# - /dev/sda3: 89.2G (home)
# - /dev/sda4: 4G (swap)

DISK="/dev/sda"

# Function to create partitions using cfdisk
create_partitions() {
  echo "Creating partitions on $DISK..."
  cfdisk $DISK
  echo "Ensure you create the following partitions:"
  echo "  1. /boot (1G, type Linux)"
  echo "  2. Swap (4G, type Linux swap)"
  echo "  3. / (25G, type Linux)"
  echo "  4. /home (Remaining space, type Linux)"
  echo "Press Enter to continue after completing partitioning..."
  read
}

# Function to format partitions
format_partitions() {
  echo "Formatting partitions..."
  mkfs.ext4 ${DISK}1 -L boot       # Format boot
  mkfs.ext4 ${DISK}2 -L root       # Format root
  mkfs.ext4 ${DISK}3 -L home       # Format home
  mkswap ${DISK}4                  # Format swap
  swapon ${DISK}4                  # Enable swap
}

# Function to mount partitions
mount_partitions() {
  echo "Mounting partitions..."
  mount ${DISK}2 /mnt              # Mount root
  mkdir -p /mnt/boot /mnt/home
  mount ${DISK}1 /mnt/boot         # Mount boot
  mount ${DISK}3 /mnt/home         # Mount home
}

# Install base system and KDE Plasma
install_system() {
  echo "Installing base system and KDE Plasma..."
  pacstrap /mnt base linux linux-firmware vim nano networkmanager \
    xorg xorg-server plasma-meta kde-applications-meta sddm
}

# Generate fstab
generate_fstab() {
  echo "Generating fstab..."
  genfstab -U /mnt >> /mnt/etc/fstab
}

# Configure system settings
configure_system() {
  echo "Configuring system settings..."
  arch-chroot /mnt /bin/bash <<EOF
# Timezone and clock
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# Locale
sed -i 's/^#de_DE.UTF-8 UTF-8/de_DE.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" > /etc/locale.conf

# Hostname
echo "Asus" > /etc/hostname
echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   Asus.localdomain Asus" >> /etc/hosts

# Root password
echo "root:123456789" | chpasswd

# User account
useradd -m -G wheel -s /bin/bash user
echo "user:123456789" | chpasswd
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Enable services
systemctl enable NetworkManager
systemctl enable sddm
EOF
}

# Finalize installation
finalize_installation() {
  echo "Installation complete. Reboot after exiting the installer."
}

# Main script execution
main() {
  echo "Starting Arch Linux Installation Script..."
  create_partitions       # Step 1: Create partitions
  format_partitions       # Step 2: Format partitions
  mount_partitions        # Step 3: Mount partitions
  install_system          # Step 4: Install base system and KDE Plasma
  generate_fstab          # Step 5: Generate fstab
  configure_system        # Step 6: Configure system settings
  finalize_installation   # Step 7: Finalize installation
}

main
