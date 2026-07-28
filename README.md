# Atomic Brew

Fedora Sway Atomic + Homebrew-Toolchain als bootc-Image.

- Nur die Build-Toolchain im Image (`/usr`)
- Homebrew zur Laufzeit in `/var/home/linuxbrew`
- Nushell, Helix & CLI kommen per First-Boot-Brewfile aus Brew
- Nushell-Integration über `/usr/share/coaching/homebrew.nu`

## Aktivieren
    sudo bootc switch ghcr.io/cbaier-bwsa/atomic-brew:latest
    sudo systemctl reboot

## Zurückrollen
    sudo bootc rollback
    sudo systemctl reboot
