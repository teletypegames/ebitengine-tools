# CI builder image for Ebitengine projects: Go toolchain + packaging tools.
# Used by the `build` step in example-woodpecker.yaml instead of installing
# zip/make/curl on every pipeline run.
#
# Build & push (the CI runner is linux/amd64):
#   docker build --platform linux/amd64 -f builder.Dockerfile \
#     -t git.teletype.hu/internal/ebitengine-builder:latest .
#   docker push git.teletype.hu/internal/ebitengine-builder:latest

# 1.26 covers every current game repo's go.mod directive (1.25.x, 1.26.x).
FROM golang:1.26-alpine

RUN apk add --no-cache git make zip curl

WORKDIR /workspace

CMD ["/bin/sh"]
