# Dotfiles — agent instructions

This repo (source: `~/.local/share/chezmoi/`) tracks user configs for an Omarchy (Arch + Hyprland) system, managed with **chezmoi**. Files are named with chezmoi's attribute prefixes (`dot_`, `executable_`, …) and deployed as real files at their runtime locations (e.g. `~/.config/hypr/`, `~/.zshrc`) via `chezmoi apply` — there are no symlinks back into this repo.

## How it works

- The source of truth lives in `~/.local/share/chezmoi/` (itself a git repo).
- `chezmoi apply` renders the source into place at `$HOME`. It's idempotent — safe to run any time.
- `chezmoi diff` previews pending changes before applying.
- Source naming maps to target paths: `dot_config/hypr/bindings.conf` → `~/.config/hypr/bindings.conf`, `dot_zshrc` → `~/.zshrc`, `executable_foo.sh` → `foo.sh` deployed with the executable bit set, etc. See `chezmoi help` / the chezmoi docs for the full attribute list.
- `logid/logid.cfg` is tracked here for reference only (see below) — it is excluded from `chezmoi apply` via `.chezmoiignore` since it targets a root-owned system path.

## Adding a new tracked config

1. `chezmoi add <runtime-path>` — this copies the file into the source dir with the correct chezmoi-prefixed name automatically.
2. Commit the new file from `~/.local/share/chezmoi`.

## Editing tracked configs

Either:
- Edit the runtime file (e.g. `~/.config/hypr/bindings.conf`) then run `chezmoi re-add <path>` (or `chezmoi add <path>` again) to pull the change back into the source, or
- Edit directly in `~/.local/share/chezmoi/` (e.g. `dot_config/hypr/bindings.conf`) then run `chezmoi apply` to push it out to `$HOME`.

Commit from `~/.local/share/chezmoi`.

Hyprland auto-reloads on save. Waybar, walker, and terminals need a restart (`omarchy-restart-waybar`, etc.) after `chezmoi apply` touches their configs.

## Secrets

This repo is **public**, so no secret value may be committed. Secrets live in
`~/.config/chezmoi/chezmoi.toml` (outside the repo, mode 600) under `[data.*]`,
and templates reference them.

Example — `dot_config/cliamp/config.toml.tmpl`:

```
client_secret = "{{ .cliamp.ytmusic.client_secret }}"
```

with the value supplied locally in `~/.config/chezmoi/chezmoi.toml`:

```toml
[data.cliamp.ytmusic]
    client_secret = "…"
```

A file gains templating by ending its source name in `.tmpl`; the suffix is
stripped on apply. To add a new secret: move the value into `chezmoi.toml`,
rename the source file to `*.tmpl`, substitute the reference, then confirm with
`chezmoi cat <target>` that it still renders correctly.

On a fresh machine, recreate `~/.config/chezmoi/chezmoi.toml` **before** running
`chezmoi apply`, or templated files will fail to render.

## What NOT to commit

- Secrets: SSH keys, GPG keys, API tokens, `.env` files, anything matching `*credentials*`. Use the template mechanism above instead.
- Large binaries or wallpapers (see `.gitignore`).
- Auto-generated files like `nvim/lazy-lock.json` unless the user specifically wants lockfile reproducibility.
- Runtime state for the `line` app (`node_modules/`, `cache.json`, `driver.log`, `.env`) — these live alongside the managed files at `~/.local/share/line/` but are gitignored, not chezmoi-managed.

## Recovery after an accidental omarchy reset

`omarchy-refresh-*` may overwrite a managed file with an Omarchy default. To restore: `chezmoi apply` — chezmoi detects the drift and re-renders the tracked version (use `chezmoi diff` first to see what changed).

## The `logid.cfg` system file

`logid` (MX Master gestures) reads `/etc/logid.cfg` as root, so chezmoi (unprivileged) can't manage it directly. It's tracked here for reference/history only. Deploy manually after editing:

```
sudo ln -sf ~/.local/share/chezmoi/logid/logid.cfg /etc/logid.cfg && sudo systemctl restart logid
```

## Out of scope

This repo is for end-user customization. Do not edit anything in `~/.local/share/omarchy/` — that's Omarchy's managed source.
