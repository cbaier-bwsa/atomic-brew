# Atomic Brew

Fedora Sway Atomic + Homebrew-Toolchain als bootc-Image.

- Build-Toolchain im Image (`/usr`)
- Homebrew zur Laufzeit in `/var/home/linuxbrew`
- Nushell-Integration über `/usr/share/atomic/homebrew.nu`

## Aktivieren
    sudo bootc switch ghcr.io/cbaier-bwsa/atomic-brew:latest
    sudo systemctl reboot

## Zurückrollen
    sudo bootc rollback
    sudo systemctl reboot
