# Justfile
image := "ghcr.io/cbaier-bwsa/atomic-brew"
tag   := "latest"

build:
    podman build -f Containerfile -t {{image}}:base .

build-variant variant:
    podman build -f Containerfile.{{variant}} -t {{image}}:{{variant}} .

# Basis, dann Sway; :latest zeigt weiter auf Sway
build-all: build (build-variant "sway")
    podman tag {{image}}:sway {{image}}:latest

# Hyprland separat, weil additiv und (noch) nicht Teil von :latest
build-hypr: build (build-variant "hypr")

push variant:
    podman push {{image}}:{{variant}}

push-all:
    for t in base sway latest; do podman push {{image}}:$t; done

# Hyprland-Push separat halten, solange :hypr nicht in CI eingebunden ist
push-hypr:
    podman push {{image}}:hypr

lint variant="sway":
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
