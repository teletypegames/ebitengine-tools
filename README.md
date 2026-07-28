# ebitengine-tools

CI/CD templates for [Ebitengine](https://ebitengine.org) (Go) game
projects, in the same spirit as [tic80-tools](../tic80-tools).

- `example-makefile.make` — project Makefile: local dev targets
  (`build`, `wasm`, `export`, `watch`, `clean`) plus the Woodpecker
  pipeline targets (`ci-version`, `ci-export`, `ci-upload`,
  `ci-update`).
- `example-woodpecker.yaml` — Woodpecker pipeline: version → export
  (Go, `GOOS=js GOARCH=wasm`) → upload (scp to the droparea) → update
  (calls the teletypegames `/update` endpoint with
  `platform=ebitengine`).
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

The pipeline uploads `$(PROJECT)-$(VERSION).html.zip` to the droparea,
then triggers
`/update?platform=ebitengine&name=$(PROJECT)&version=$(VERSION)`.

Detailed documentation lives on the wiki: `/development/ebitengine`.
