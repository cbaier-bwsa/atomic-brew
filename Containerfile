# Containerfile — Basis: Build-Toolchain für Homebrew, keine Desktop-Umgebung
FROM quay.io/fedora-ostree-desktops/base-atomic:44

# Manche Pakete verlangen ein vorhandenes /var/roothome, sonst bricht der Build ab.
RUN mkdir -p /var/roothome

# --- Build-Toolchain für Homebrew (bleibt read-only im Image) ---
RUN dnf -y install \
        @development-tools \
        gcc gcc-c++ make \
        procps-ng curl file git \
        libxcrypt-compat && \
    dnf clean all && \
    rm -rf /var/cache/libdnf5 /var/lib/dnf /var/log/* /var/cache/ldconfig/* \
           /run/dnf /run/svnserve

# --- Overlay: Nushell-Env, /etc/skel, systemd-User-Unit ---
COPY overlay/ /

RUN systemctl --global enable homebrew-bootstrap.service

# Bekannte Upstream-Regression bei composefs-Root (ostreedev/ostree#3193, RHBZ#2348934):
# systemd-remount-fs.service scheitert bei jedem Boot mit "mount: /: fsconfig() failed:
# overlay: No changes allowed in reconfigure", weil es "/" laut /etc/fstab remounten will,
# was mit dem composefs-Overlay-Root nicht kompatibel ist. Harmlos (blockiert nichts), aber
# erzeugt einen echten "failed unit"-Eintrag. Fix liegt upstream in systemd (PR #36867), bis
# dahin maskieren, wie von den betroffenen Projekten selbst als Workaround genannt.
RUN systemctl mask systemd-remount-fs.service

# --- initramfs neu erzeugen, damit 90-no-gpu.conf aus dem Overlay greift ---
# Muss nach allen dnf-/COPY-Schritten laufen, die Kernel, dracut oder Plymouth betreffen.
RUN set -eu; \
    KVER="$(ls /usr/lib/modules)"; \
    [ "$(echo "$KVER" | wc -l)" -eq 1 ] || { echo "Mehr als ein Kernel: $KVER" >&2; exit 1; }; \
    DRACUT_NO_XATTR=1 dracut --no-hostonly --reproducible --add ostree \
        --kver "$KVER" -f "/usr/lib/modules/$KVER/initramfs.img"

# --- bootc-Lint als Qualitätssicherung im Build ---
RUN bootc container lint

LABEL org.opencontainers.image.title="Atomic Brew (Basis)" \
      org.opencontainers.image.description="Fedora Atomic Basis + Homebrew-Toolchain, CLI aus Brewfile" \
      containers.bootc="1"
