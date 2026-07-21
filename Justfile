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
