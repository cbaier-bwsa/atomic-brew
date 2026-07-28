# /etc/skel/.bash_profile
# Homebrew-PATH früh verfügbar machen (falls schon installiert)
[ -x /var/home/linuxbrew/.linuxbrew/bin/brew ] && \
    eval "$(/var/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# In Nushell wechseln, sobald es aus Brew vorhanden ist
if command -v nu >/dev/null 2>&1; then
    exec nu
fi
