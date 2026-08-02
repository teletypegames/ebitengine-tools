# CI builder image for Ebitengine projects: Go toolchain + packaging tools
# + the X11/GL/ALSA dev libraries needed for the native linux-x64 (cgo) build.
# Used by the `build` and `binaries` steps in example-woodpecker.yaml instead
# of installing everything on every pipeline run.
#
# Debian-based (not alpine): the linux-x64 game binary must link against
# glibc, otherwise it won't run on regular desktop distros.
#
# Build & push (the CI runner is linux/amd64):
#   docker build --platform linux/amd64 -f builder.Dockerfile \
#     -t git.teletypegames.org/internal/ebitengine-builder:latest .
#   docker push git.teletypegames.org/internal/ebitengine-builder:latest

# 1.26 covers every current game repo's go.mod directive (1.25.x, 1.26.x).
FROM golang:1.26-bookworm

# Ebitengine linux build dependencies:
# https://ebitengine.org/en/documents/install.html (Debian/Ubuntu section)
RUN apt-get update && apt-get install -y --no-install-recommends \
        git make zip curl jq pkg-config \
        libc6-dev libgl1-mesa-dev libglu1-mesa-dev \
        libx11-dev libxcursor-dev libxi-dev libxinerama-dev \
        libxrandr-dev libxxf86vm-dev \
        libasound2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]
