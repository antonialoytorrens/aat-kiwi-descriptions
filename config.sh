#!/bin/bash
set -euxo pipefail

# Locale
echo "Configuring Locales..."
# Generate requested locales
{
    echo "ca_ES.UTF-8 UTF-8"
    echo "es_ES.UTF-8 UTF-8"
    echo "en_US.UTF-8 UTF-8"
} >> /etc/locale.gen
locale-gen
# Set default locale to ca_ES.UTF-8
update-locale LANG=ca_ES.UTF-8

# Timezone
echo "Europe/Madrid" > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Madrid /etc/localtime

# Users
echo "Configuring Users..."
useradd -m -s /bin/bash user
echo "user:live" | chpasswd

# Groups
for g in cdrom floppy sudo audio dip video plugdev netdev bluetooth lpadmin scanner; do
    groupadd -f "$g"
done

# Picked from standard debian user (groups $(whoami) )
usermod -aG cdrom,floppy,sudo,audio,dip,video,plugdev,netdev,bluetooth,lpadmin,scanner user

# Network
echo "Configuring Network..."
# Enable systemd-networkd if needed, or NetworkManager
systemctl enable NetworkManager

# SSH
systemctl enable ssh

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
