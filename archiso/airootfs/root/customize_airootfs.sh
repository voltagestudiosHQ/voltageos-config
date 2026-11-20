#!/usr/bin/env bash
set -euo pipefail

if [[ -f /boot/Image ]]; then
  pacman-key --init
  pacman-key --populate archlinuxarm
  install -Dm644 /usr/share/voltageos/archiso.conf /etc/mkinitcpio.conf.d/archiso.conf
  install -Dm644 /usr/share/voltageos/linux-aarch64.preset /etc/mkinitcpio.d/linux-aarch64.preset
  install -m644 /boot/Image /boot/vmlinuz-linux-aarch64
  mkinitcpio -p linux-aarch64
fi

useradd --create-home --groups wheel --shell /bin/bash voltage
passwd --lock voltage
passwd --lock root

chmod 0440 /etc/sudoers.d/10-voltage-live
visudo --check --file=/etc/sudoers.d/10-voltage-live

systemctl enable NetworkManager.service
systemctl enable chronyd.service
systemctl enable firewalld.service
systemctl enable sddm.service

for settings in /etc/calamares/settings.conf /usr/share/calamares/settings.conf; do
    if [[ -f "$settings" ]] && grep -q '^branding:' "$settings"; then
        sed -i 's/^branding:.*/branding: voltageos/' "$settings"
    fi
done
