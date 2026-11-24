# ebitengine-tools

CI/CD templates for [Ebitengine](https://ebitengine.org) (Go) game
projects, in the same spirit as [tic80-tools](../tic80-tools).

- `example-makefile.make` — project Makefile: the shared targets (`build`,
  `run`, `check`, `web`, `clean`, `mac-release`, see below) plus `export`,
  `watch`, the native binary targets (`binaries`, `binary-win-x86`,
  `binary-win-x64`, `binary-linux-x64`) and `binaries-mac`.
- `.woodpecker.yaml` (written by New Game, not kept here) — a one-line
  marker (`platform: ebitengine`): the full pipeline (version → build → binaries → artifact → publish) is served by the update server's Woodpecker
  configuration extension — preview it with
  `curl "https://teletypegames.org/build/config?platform=ebitengine"`.
- `example-tasks.json` — VS Code `.vscode/tasks.json`: `build` (the default
  build task) and `web` as `warpengine` tasks, and `run (native)` (`make run`
  on this computer, with a local Go).
- `hello/` — the smallest Ebitengine game: a window that prints
  "Hello World" (`main.go`, `go.mod`, `go.sum`, `.gitignore`). The Go
  module is called `game`, so it builds under any project name.
- `warp-template.json` — what *WarpEngine: New Game* (WarpEngine
  Toolbox) copies for "Start from the template only": the Makefile,
  the VS Code tasks and the `hello/` sources at the project root. The
  toolbox sets `PROJECT` and writes `.woodpecker.yaml` and
  `metadata.json` itself.
- `web/index.html` — the HTML shell downloaded by `make web` / `make export` and
  packaged next to the `.wasm` build.

## Dev container

`warp-template.json` has a `devcontainer` key that the WarpEngine Toolbox reads
(an older toolbox ignores it): a new project gets `.devcontainer/` from
`example-devcontainer.json` and `example-devcontainer.Dockerfile` — the CI
builder image the host names (`{builderImage}`) plus git and a `dev` user —
so a computer with only Docker builds with the same toolchain as the pipeline.
The tasks of `example-devcontainer-tasks.json` are merged into
`.vscode/tasks.json`: `dev image` builds the container image, `play` builds the
game and plays it in the host's web runtime. The Go module cache (`GOPATH`) of the image belongs to `dev` there. `make web` builds the WebAssembly version with its page into `dist/`, which the `play` task plays in the Play panel. The game window does not open in the container: `run (native)` runs `make run` on this computer, which needs Go here.
The container editor gets its extensions from `example-devcontainer.json`: the WarpEngine Toolbox, Makefile Tools (its configure prompts off; the Toolbox tasks build) and the Go extension (it installs `gopls` into the container on first use). It also mounts the computer's Docker socket, with the Docker CLI in the image and `dev` in the socket's group, so the Toolbox lists, starts and restarts the local engine's containers from inside the container.
For an existing game repo, *WarpEngine: Add Dev Container* adds it and merges
the tasks, keeping yours.

## Makefile contract

The Makefile has the targets every WarpEngine template shares: `build`, `run`, `check` (the CI's check step runs it in the builder image),
`clean`, `web` (the WebAssembly build with its page in `dist/`, which Play plays) and `mac-release` (the mac zips, built and released on a Mac). `warp-engine check makefile` of the
[WarpEngine CLI](https://wiki.teletypegames.org/godoc/warp-engine-cli/latest/cmd/warp-engine/)
checks a project against it. `check` is `go vet`.

## Usage in a game repo

1. Copy `example-makefile.make` to `Makefile` and set `PROJECT`
   (the native binary is built to `bin/$(PROJECT)`).
2. Create `.woodpecker.yaml` with the line `platform: ebitengine` (a one-line marker — the
   pipeline itself is served by the update server; add `name:` when the
   software name differs from the repo name) and add the
   `application_token` secret in Woodpecker (an ApplicationToken with
   the `update` + `upload` scopes, created in the admin).
3. Copy `example-tasks.json` to `.vscode/tasks.json`.

The served pipeline uploads `$(PROJECT)-$(VERSION).html.zip` plus the native
binary zips (`$(PROJECT)-$(VERSION)-<target>.zip`, currently `win-x86`,
`win-x64`, `linux-x64`) via `/build/upload`, then triggers
`/build/publish?platform=ebitengine&name=$(PROJECT)&version=$(VERSION)`.
The updater picks up the binary zips by naming convention and attaches
them to the release as assets (see `teletypegames/NOTES_BINARY_PLAN.md`).

Binary zip layout: a single root folder
(`$(PROJECT)-$(VERSION)-<target>/`) containing the executable (plus
LICENSE/README.md when present). The zips are created with unix `zip`,
so the executable bit survives on the linux binary.

## mac targets (mac-x64, mac-arm64)

Ebitengine requires cgo on darwin (GLFW/Metal — purego does not cover
it), so the mac targets cannot be cross-compiled from the linux builder.
They are built **on a mac host** instead, packaged as a minimal
`.app` bundle (generated Info.plist, ad-hoc `codesign`).

`mac-release` builds both mac zips (`mac-x64`, `mac-arm64`) on the Mac and releases them with the
[WarpEngine CLI](https://wiki.teletypegames.org/godoc/warp-engine-cli/latest/cmd/warp-engine/):
`warp-engine release upload` sends the zips into the release's folder and
`warp-engine release publish --platform ebitengine` publishes the release again, which keeps
the CI's files and adds these. Install the CLI once on the Mac (into `~/.local/bin`):

```sh
curl -fsSL https://git.teletypegames.org/engines/warp-engine-cli/raw/branch/master/install.sh | sh
```

or, with Go, `go install git.teletypegames.org/engines/warp-engine-cli/cmd/warp-engine@latest`.
The token is an application token with the `update` + `upload` scopes; the server is
`WARP_SERVER` (default `https://teletypegames.org`):

```sh
WARP_TOKEN=... make mac-release VERSION=x.y.z
```

Run it after the CI pipeline has created the release.
Ad-hoc signature means Gatekeeper shows the "unidentified developer"
warning (right-click → Open); proper signing/notarization needs an
Apple Developer account.

## Builder image

`builder.Dockerfile` bakes the pipeline's build-step dependencies
(Go + git/make/zip/curl/jq and the X11/GL/ALSA dev libraries needed by
the cgo `linux-x64` build) into
`git.teletypegames.org/build/ebitengine-builder`. Debian-based so
the linux binary links against glibc:

```sh
docker build --platform linux/amd64 -f builder.Dockerfile \
  -t git.teletypegames.org/build/ebitengine-builder:latest .
docker push git.teletypegames.org/build/ebitengine-builder:latest
```

Detailed documentation lives on the wiki: `/development/ebitengine`.
