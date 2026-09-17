# /etc/skel/.bash_profile
# Homebrew-PATH kommt bereits aus /etc/profile.d/homebrew.sh (laeuft vor
# dieser Datei und deckt auch nicht-login-interaktive Shells ab).

# In Nushell wechseln, sobald es aus Brew vorhanden ist -- aber nur bei einer
# echten interaktiven Konsolen-Session. SDDMs /etc/sddm/wayland-session reexecs
# als "bash --login <script> <session-cmd>", was ~/.bash_profile ebenfalls laedt,
# aber nicht interaktiv ist ($- enthaelt kein "i"). Ein exec hier wuerde den
# eigentlichen Session-Befehl (z.B. "uwsm start ...") verschlucken, bevor er
# ausgefuehrt wird -- schwarzer Bildschirm ohne jede Fehlermeldung.
case $- in
    *i*)
        command -v nu >/dev/null 2>&1 && exec nu
        ;;
esac
