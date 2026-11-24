# CI builder image for Ebitengine projects: Go toolchain + packaging tools
# + the X11/GL/ALSA dev libraries needed for the native linux-x64 (cgo) build.
# Used by the `build` and `binaries` steps of the served pipeline instead
# of installing everything on every pipeline run.
#
# Debian-based (not alpine): the linux-x64 game binary must link against
# glibc, otherwise it won't run on regular desktop distros.
#
# Build & push (the CI runner is linux/amd64):
#   docker build --platform linux/amd64 -f builder.Dockerfile \
#     -t git.teletypegames.org/build/ebitengine-builder:latest .
#   docker push git.teletypegames.org/build/ebitengine-builder:latest

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

# linux-arm64 cross-build (Raspberry Pi, Odroid, retro handhelds). Ebitengine
# needs cgo on Linux, so the arm64 target needs a cross gcc plus the same
# X11/GL/ALSA headers for arm64. Debian's main mirror carries arm64, so
# `dpkg --add-architecture` is enough — no ports repository needed.
RUN dpkg --add-architecture arm64 \
    && apt-get update && apt-get install -y --no-install-recommends \
        gcc-aarch64-linux-gnu libc6-dev-arm64-cross \
        libgl1-mesa-dev:arm64 libglu1-mesa-dev:arm64 \
        libx11-dev:arm64 libxcursor-dev:arm64 libxi-dev:arm64 \
        libxinerama-dev:arm64 libxrandr-dev:arm64 libxxf86vm-dev:arm64 \
        libasound2-dev:arm64 \
    && rm -rf /var/lib/apt/lists/*

# Our own Go modules (engines/inkwell, engines/gorpg) are served by the forge,
# not by proxy.golang.org, and are absent from the public checksum database.
ENV GOPRIVATE=git.teletypegames.org

WORKDIR /workspace

CMD ["/bin/bash"]
