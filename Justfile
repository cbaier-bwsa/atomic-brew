# Justfile
image := "ghcr.io/cbaier-bwsa/atomic-brew"
tag   := "latest"

build:
    podman build -t {{image}}:{{tag}} .

push:
    podman push {{image}}:{{tag}}

lint:
    podman run --rm {{image}}:{{tag}} bootc container lint

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
