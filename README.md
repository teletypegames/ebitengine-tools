# ebitengine-tools

CI/CD templates for [Ebitengine](https://ebitengine.org) (Go) game
projects, in the same spirit as [tic80-tools](../tic80-tools).

- `example-makefile.make` — project Makefile: local dev targets
  (`build`, `wasm`, `export`, `watch`, `clean`), native binary targets
  (`binaries`, `binary-win-x86`, `binary-win-x64`, `binary-linux-x64`)
  plus the Woodpecker pipeline targets (`ci-version`, `ci-export`,
  `ci-binaries`, `ci-upload`, `ci-update`).
- `example-woodpecker.yaml` — Woodpecker pipeline: version → export
  (Go, `GOOS=js GOARCH=wasm`) → binaries (native desktop zips) →
  upload (scp to the droparea) → update (calls the teletypegames
  `/update` endpoint with `platform=ebitengine`).
- `example-tasks.json` — VS Code `.vscode/tasks.json` with the common
  dev tasks: **Run** (`go run .`, default build task, `Cmd+Shift+B`),
  **Build & Run**, **Build WASM** and **Make build**.
- `web/index.html` — the HTML shell downloaded by `make export` and
  packaged next to the `.wasm` build.

## Usage in a game repo

1. Copy `example-makefile.make` to `Makefile` and set `PROJECT`
   (the native binary is built to `bin/$(PROJECT)`).
2. Copy `example-woodpecker.yaml` to `.woodpecker.yaml` and add the
   `droparea_ssh_password` / `update_secret_key` secrets in Woodpecker.
3. Copy `example-tasks.json` to `.vscode/tasks.json` and replace the
   binary name (`ebitenginedemo`) with `$(PROJECT)`.

The pipeline uploads `$(PROJECT)-$(VERSION).html.zip` plus the native
binary zips (`$(PROJECT)-$(VERSION)-<target>.zip`, currently `win-x86`,
`win-x64`, `linux-x64`) to the droparea, then triggers
`/update?platform=ebitengine&name=$(PROJECT)&version=$(VERSION)`.
The updater picks up the binary zips by naming convention and attaches
them to the release as assets (see `teletypegames/NOTES_BINARY_PLAN.md`).

Binary zip layout: a single root folder
(`$(PROJECT)-$(VERSION)-<target>/`) containing the executable (plus
LICENSE/README.md when present). The zips are created with unix `zip`,
so the executable bit survives on the linux binary. mac targets need a
mac runner (or osxcross) and are not part of the pipeline yet.

## Builder image

`builder.Dockerfile` bakes the pipeline's build-step dependencies
(Go + git/make/zip/curl/jq and the X11/GL/ALSA dev libraries needed by
the cgo `linux-x64` build) into
`git.teletypegames.org/internal/ebitengine-builder`. Debian-based so
the linux binary links against glibc:

```sh
docker build --platform linux/amd64 -f builder.Dockerfile \
  -t git.teletypegames.org/internal/ebitengine-builder:latest .
docker push git.teletypegames.org/internal/ebitengine-builder:latest
```

Detailed documentation lives on the wiki: `/development/ebitengine`.
