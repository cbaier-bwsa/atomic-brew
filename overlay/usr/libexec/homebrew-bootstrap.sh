#!/usr/bin/env bash
# /usr/libexec/homebrew-bootstrap.sh
# Wird von homebrew-bootstrap.service ausgeführt. Prüft zuerst die Internetverbindung,
# statt das direkt an "curl | bash" scheitern zu lassen: Ohne Netz (typisch beim allerersten
# Boot nach der Installation, bevor WLAN eingerichtet ist) würde der Unit sonst in den
# "failed"-Status gehen, was Noctalias Failed-Unit-Erkennung als generische Fehlermeldung
# anzeigt. Stattdessen hier eine eigene, verständliche Meldung per notify-send und ein Exit-Code,
# den der Service (via SuccessExitStatus) als Erfolg wertet. ConditionPathExists im Service sorgt
# dafür, dass der Bootstrap beim nächsten Login (z.B. nach WLAN-Einrichtung) erneut versucht wird.
# notify-send (Paket libnotify) braucht hier keine eigene Installation: bereits im unveränderten
# Upstream-Basisimage quay.io/fedora-ostree-desktops/base-atomic:44 vorhanden (verifiziert per
# `podman run --rm quay.io/fedora-ostree-desktops/base-atomic:44 rpm -q libnotify`).
set -euo pipefail

BREW_BIN=/var/home/linuxbrew/.linuxbrew/bin/brew
NO_NETWORK_EXIT=91

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        # expire-time=0: Meldung bleibt stehen, bis sie manuell weggeklickt wird (statt nach
        # ein paar Sekunden automatisch zu verschwinden, wie es bei fehlendem Internet sonst
        # leicht unbemerkt bliebe).
        notify-send --urgency=critical --expire-time=0 --icon=network-wireless-disconnected "$@"
    else
        printf '%s: %s\n' "$1" "$2" >&2
    fi
}

if [[ -x "$BREW_BIN" ]]; then
    exit 0
fi

if ! curl -fsS --max-time 5 -o /dev/null https://raw.githubusercontent.com; then
    # Sprache anhand der Session-Locale wählen (systemd --user importiert LANG aus der
    # Login-Umgebung); alles außer de_* fällt auf Englisch zurück.
    case "${LANG:-}" in
        de_*)
            notify "Keine Internetverbindung" \
                "Die Ersteinrichtung von Atomic Brew benötigt eine Internetverbindung. Bitte WLAN einrichten oder Ethernet verbinden und neu starten."
            ;;
        *)
            notify "No internet connection" \
                "Atomic Brew's initial setup requires an internet connection. Please set up Wi-Fi or connect Ethernet, then restart."
            ;;
    esac
    exit "$NO_NETWORK_EXIT"
fi

export NONINTERACTIVE=1
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

eval "$("$BREW_BIN" shellenv)"
brew bundle --file=/usr/share/coaching/Brewfile
