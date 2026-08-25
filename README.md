# Atomic Brew

Fedora Atomic + Homebrew-Toolchain als bootc-Image, in vier gestaffelten Varianten.

- Nur die Build-Toolchain im Image (`/usr`), Rest read-only
- Homebrew zur Laufzeit in `/var/home/linuxbrew`, non-root per systemd-User-Unit
- Nushell, Helix & CLI-Tools kommen per First-Boot-Brewfile aus Brew
- Nushell-Integration über `/usr/share/coaching/homebrew.nu`
- Images sind mit cosign signiert (`cosign.pub` liegt im Repo)

## Varianten

| Tag         | Basis         | Inhalt                                  | In CI/`:latest` |
|-------------|---------------|------------------------------------------|------------------|
| `:base`     | —             | Nur die Homebrew-Build-Toolchain         | ja (Zwischenstufe) |
| `:hypr`     | `:base`       | Hyprland-Desktop (COPR, SDDM)            | ja (Zwischenstufe) |
| `:noctalia` | `:hypr`       | Noctalia-Shell auf Hyprland              | ja, = `:latest`  |
| `:sway`     | `:base`       | Sway-Desktop (`@swaywm`)                 | nein (additiv)   |

`:latest` zeigt auf `:noctalia` (Hauptstrang: `:base` → `:hypr` → `:noctalia`). `:sway` ist ein
eigenständiger, additiver Zweig (nicht Teil von `:latest`) und wird aktuell nur manuell
gebaut/gepusht.

## Aktivieren
    sudo bootc switch ghcr.io/cbaier-bwsa/atomic-brew:latest      # Hyprland + Noctalia (Standard)
    sudo bootc switch ghcr.io/cbaier-bwsa/atomic-brew:hypr        # nur Hyprland
    sudo bootc switch ghcr.io/cbaier-bwsa/atomic-brew:sway        # Sway
    sudo systemctl reboot

## Zurückrollen
    sudo bootc rollback
    sudo systemctl reboot

## Bauen & Pushen

Alle Befehle über `just` (siehe `Justfile`):

    just build              # :base
    just build-hypr         # :base -> :hypr
    just build-all          # :base -> :hypr -> :noctalia, taggt :latest
    just build-sway         # :base -> :sway

    just lint <variant>     # bootc container lint gegen einen gebauten Tag
    just login              # podman login ghcr.io
    just push <variant>     # einzelnes Tag pushen
    just push-all           # base, hypr, noctalia, latest
    just push-sway

    just iso                # Installer-ISO über bootc-image-builder (braucht .docs/installer-config.toml)

Es gibt keine separate Test-Suite — `bootc container lint` läuft als `RUN`-Schritt in jedem
Containerfile selbst, ein erfolgreicher `podman build` schließt den Lint also mit ein.

## CI/CD

`.github/workflows/build.yml` baut und pusht `:base`/`:hypr`/`:noctalia`/`:latest` und signiert
die gepushten Digests mit cosign — bei Push auf `main`, wöchentlich per Cron (Basis-Updates) und
manuell per `workflow_dispatch`. `:sway` ist noch nicht angebunden.

Signatur prüfen:

    cosign verify --key cosign.pub --insecure-ignore-tlog=true \
        ghcr.io/cbaier-bwsa/atomic-brew:latest
