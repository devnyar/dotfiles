# Dotfiles — agent instructions

This repo (source: `~/.local/share/chezmoi/`) tracks user configs for three classes of machine — an Omarchy (Arch + Hyprland) workstation, macOS workstations, and headless Linux servers (Proxmox hosts and LXCs) — managed with **chezmoi**. Files are named with chezmoi's attribute prefixes (`dot_`, `executable_`, …) and deployed as real files at their runtime locations (e.g. `~/.config/hypr/`, `~/.zshrc`) via `chezmoi apply` — there are no symlinks back into this repo.

## How it works

- The source of truth lives in `~/.local/share/chezmoi/` (itself a git repo).
- `chezmoi apply` renders the source into place at `$HOME`. It's idempotent — safe to run any time.
- `chezmoi diff` previews pending changes before applying.
- Source naming maps to target paths: `dot_config/hypr/bindings.conf` → `~/.config/hypr/bindings.conf`, `dot_zshrc` → `~/.zshrc`, `executable_foo.sh` → `foo.sh` deployed with the executable bit set, etc. See `chezmoi help` / the chezmoi docs for the full attribute list.
- `logid/logid.cfg` is tracked here for reference only (see below) — it is excluded from `chezmoi apply` via `.chezmoiignore` since it targets a root-owned system path.

## Machine classes

One repo, three targets. `.chezmoitemplates/machine-class` resolves the class of
the machine being applied to:

| Class | Detected when | Gets |
|---|---|---|
| `omarchy` | `osRelease.id` is `omarchy`, or `idLike` contains `arch` | everything |
| `mac` | `.chezmoi.os` is `darwin` | everything except Wayland/systemd/Omarchy-coupled configs |
| `server` | any other Linux | shell + core CLI only (`.bashrc` `.bash_profile` `.zshrc` `.config/shell` `.config/git` `.config/tmux` `.config/btop` `.local/bin`) |

`.chezmoi.osRelease` does not exist on macOS, so the darwin check must come
first — that's why the class lives in one shared template instead of being
re-derived per file.

Override the detection on any machine with `machine = "omarchy" | "mac" | "server"`
under `[data]` in `~/.config/chezmoi/chezmoi.toml`.

`.chezmoiignore` is itself a template: it consumes the class and excludes the
per-class target lists. To check what a class would get without owning such a
machine:

```
printf '[data]\n machine = "server"\n' > /tmp/c.toml
chezmoi managed --config=/tmp/c.toml    # what would deploy
chezmoi cat --config=/tmp/c.toml ~/.config/git/config
```

Note `stat`/`lookPath` in templates evaluate on the machine running `apply`, so
those render correctly on the real host even if a dry run here says otherwise.

## Shell layout

Precedence, lowest to highest — each layer may override the one before it:

1. **`~/.config/shell/common.sh`** — the portable base, sourced by both
   `.bashrc` and `.zshrc` on every machine. PATH (Homebrew, Android SDK on both
   Linux and macOS layouts, `~/.local/bin`), listing aliases (eza → GNU ls →
   BSD ls), `lanip`/`wanip`, `mkcd`. Must stay POSIX-ish: no bashisms, no
   zsh-isms. Never assume GNU flags — macOS ships BSD userland.
2. **Platform config** — Omarchy's `default/bash/{rc,aliases,fns}` and
   oh-my-zsh, both guarded by file-existence checks so the same rc files work
   on a Proxmox host with neither installed.
3. **Per-host files, NOT managed by chezmoi** — create these only where needed:
   - `~/.bashrc.local`, `~/.zshrc.local` — host-specific aliases, PATH, PS1, nvm
   - `~/.zshrc.pre.local` — sourced *before* oh-my-zsh, for `ZSH_THEME` and
     `plugins` (they have no effect if set afterwards)

Anything host-specific belongs in layer 3, never in the tracked rc files.

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
