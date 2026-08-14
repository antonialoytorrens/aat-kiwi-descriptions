#!/bin/bash
set -euxo pipefail

# Network
echo "Configuring Network..."
# Enable systemd-networkd if needed, or NetworkManager
#baseInsertService NetworkManager
systemctl enable NetworkManager

# SSH
#baseInsertService sshd
systemctl enable ssh

# Unattended Upgrades
#baseInsertService unattended-upgrades
systemctl enable unattended-upgrades

# Preseed
if [ -f /tmp/preseed.cfg ]; then
    echo "Applying preseed configuration..."
    debconf-set-selections /tmp/preseed.cfg
fi

# GRUB Theme
if [ -d /boot/grub/themes/live-theme ]; then
    echo "Configuring GRUB theme..."
    echo 'GRUB_THEME="/boot/grub/themes/live-theme/theme.txt"' >> /etc/default/grub
    # update-grub might need /proc /sys /dev mounted, which kiwi handles, but sometimes fails in chroot if not careful.
    # Usually safer to rely on kiwi bootloader config or run it if verified working.
    update-grub || true
fi

# Device-specific post-install hook, provided by the BSP overlay (if any).
# Not part of the final image, so remove it once it has run.
if [ -f /postinst.sh ]; then
    echo "Running device-specific postinst.sh..."
    bash /postinst.sh
    rm -f /postinst.sh
fi

exit 0
