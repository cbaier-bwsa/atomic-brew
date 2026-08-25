# Justfile
image := "ghcr.io/cbaier-bwsa/atomic-brew"
tag   := "latest"

build:
    podman build -f Containerfile -t {{image}}:base .

build-variant variant:
    podman build -f Containerfile.{{variant}} -t {{image}}:{{variant}} .

# Hyprland separat anwählbar, als Zwischenstufe des Hauptstrangs
build-hypr: build (build-variant "hypr")

# Hauptstrang: Basis -> Hyprland -> Noctalia; :latest zeigt auf Noctalia
build-all: build-hypr (build-variant "noctalia")
    podman tag {{image}}:noctalia {{image}}:latest

# Sway separat halten, seit :noctalia der Hauptstrang ist (nicht mehr Teil von :latest)
build-sway: build (build-variant "sway")

push variant:
    podman push {{image}}:{{variant}}

push-all:
    for t in base hypr noctalia latest; do podman push {{image}}:$t; done

# Sway-Push separat halten, solange :sway nicht in CI eingebunden ist
push-sway:
    podman push {{image}}:sway

lint variant="noctalia":
    podman run --rm {{image}}:{{variant}} bootc container lint

login:
    podman login ghcr.io

# Installer-ISO bauen -> output/bootiso/install.iso
# Braucht .docs/installer-config.toml (User-Customizations, gitignored).
# sudo beim pull ist Absicht: bib liest den Root-Storage, nicht den rootless.
iso:
    sudo podman pull {{image}}:{{tag}}
    mkdir -p output
    sudo podman run --rm -it --privileged \
      --security-opt label=type:unconfined_t \
      -v {{justfile_directory()}}/.docs/installer-config.toml:/config.toml:ro \
      -v {{justfile_directory()}}/output:/output \
      -v /var/lib/containers/storage:/var/lib/containers/storage \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type anaconda-iso --rootfs btrfs {{image}}:{{tag}}
