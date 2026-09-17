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
    local urgency="$1" icon="$2" title="$3" body="$4"
    if command -v notify-send >/dev/null 2>&1; then
        # org.freedesktop.Notifications wird bei :noctalia ausschließlich von Noctalias eigenem
        # Daemon bedient (mako.service ist global maskiert, siehe Containerfile.noctalia). Der
        # Daemon ist aber nur ein xdg-autostart-Programm, kein systemd-Unit, und hat beim
        # allerersten Login -- dieser Service läuft direkt nach default.target, ohne auf die
        # grafische Session zu warten -- den Namen oft noch nicht übernommen. Ohne Owner versucht
        # D-Bus, den *maskierten* mako.service zu aktivieren; notify-send bricht dann mit "unit is
        # masked" ab, was wegen `set -e` den gesamten Bootstrap wieder in den failed-Status riss
        # (live beobachtet: Erststart ohne Internet zeigte wieder die generische
        # "Failed unit"-Meldung statt der eigenen). Deshalb kurz auf einen Owner warten.
        local tries=0
        while [[ $tries -lt 20 ]] && ! busctl --user list-names 2>/dev/null | grep -q org.freedesktop.Notifications; do
            sleep 1
            tries=$((tries + 1))
        done
        # expire-time=0: Meldung bleibt stehen, bis sie manuell weggeklickt wird (statt nach
        # ein paar Sekunden automatisch zu verschwinden, wie es leicht unbemerkt bliebe).
        # "|| printf" statt uns auf das Gelingen zu verlassen: selbst nach der Wartezeit darf ein
        # D-Bus-Fehler hier nicht den ganzen Bootstrap wieder in den failed-Status reißen.
        notify-send --urgency="$urgency" --expire-time=0 --icon="$icon" "$title" "$body" \
            || printf '%s: %s\n' "$title" "$body" >&2
    else
        printf '%s: %s\n' "$title" "$body" >&2
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
            notify critical network-wireless-disconnected "Keine Internetverbindung" \
                "Die Ersteinrichtung von Atomic Brew benötigt eine Internetverbindung. Bitte WLAN einrichten oder Ethernet verbinden und neu starten."
            ;;
        *)
            notify critical network-wireless-disconnected "No internet connection" \
                "Atomic Brew's initial setup requires an internet connection. Please set up Wi-Fi or connect Ethernet, then restart."
            ;;
    esac
    exit "$NO_NETWORK_EXIT"
fi

export NONINTERACTIVE=1
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash

eval "$("$BREW_BIN" shellenv)"
brew bundle --file=/usr/share/coaching/Brewfile

case "${LANG:-}" in
    de_*)
        notify normal task-complete "Ersteinrichtung abgeschlossen" \
            "Homebrew und die CLI-Tools aus dem Brewfile sind installiert."
        ;;
    *)
        notify normal task-complete "Initial setup complete" \
            "Homebrew and the CLI tools from the Brewfile have been installed."
        ;;
esac
