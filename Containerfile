# Containerfile
FROM quay.io/fedora-ostree-desktops/sway-atomic:44

# Manche Pakete verlangen ein vorhandenes /var/roothome, sonst bricht der Build ab.
RUN mkdir -p /var/roothome

# --- Build-Toolchain für Homebrew (bleibt read-only im Image) ---
RUN dnf -y install \
        @development-tools \
        gcc gcc-c++ make \
        procps-ng curl file git \
        libxcrypt-compat \
        nushell helix && \
    dnf clean all && \
    rm -rf /var/cache/libdnf5 /var/lib/dnf /var/log/* /var/cache/ldconfig/* \
           /run/dnf /run/svnserve

# --- Overlay: Nushell-Env, /etc/skel, systemd-User-Unit ---
COPY overlay/ /

RUN systemctl --global enable homebrew-bootstrap.service

# --- bootc-Lint als Qualitätssicherung im Build ---
RUN bootc container lint

LABEL org.opencontainers.image.title="Atomic Brew" \
      org.opencontainers.image.description="Fedora Sway Atomic + Homebrew-Toolchain" \
      containers.bootc="1"
