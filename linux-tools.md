# User-level CLI tools on Linux (no root)

The Mac gets these from Homebrew (`~/.dotfiles/Brewfile`, "modern CLI core").
On the RHEL 9 VDI there is no sudo, so they are installed per user by
[`install-linux-tools.sh`](install-linux-tools.sh):

- release archives from the projects' **official GitHub releases** only,
- static `x86_64-unknown-linux-musl` builds where offered (glibc-independent),
- each download checked against the **pinned SHA-256** below before unpacking,
- unpacked into `~/.local/opt/<tool>-<version>/`, binaries symlinked into
  `~/.local/bin` (already on `PATH` for all shells, see `bashrc`),
- bundled bash completions -> `~/.local/share/bash-completion/completions/`,
  bundled man pages -> `~/.local/share/man/man1/`; completions for gh, delta,
  starship, uv and uvx are generated into the same dir (lazy-loaded, so they
  cost no startup time).

Re-running the script is a no-op for versions already installed. To upgrade,
bump the row in the script and here, then re-run; the old
`~/.local/opt/<tool>-<old>` stays around for rollback and can be deleted.

Checksum source: "file" = the release's published checksum file (and it
matched GitHub's asset digest); "digest" = GitHub's per-asset SHA-256 digest
from the releases API, used where the project publishes no checksum file.

Pinned 2026-10-09 (latest stable releases at that date):

| tool | version | asset (URL prefix `https://github.com/`) | SHA-256 | source |
|---|---|---|---|---|
| starship | 1.26.0 | `starship/starship/releases/download/v1.26.0/starship-x86_64-unknown-linux-musl.tar.gz` | `b7c232b0e8249d8e55a40beb79c5c43a7d370f3f9408bd215deb0170daeaadf3` | file |
| fzf | 0.74.4 | `junegunn/fzf/releases/download/v0.74.4/fzf-0.74.4-linux_amd64.tar.gz` | `05e6813a337cc722c3ed07e54a764b75cc5d671e2e60459db0ba696ee5fa7504` | file |
| zoxide | 0.10.0 | `ajeetdsouza/zoxide/releases/download/v0.10.0/zoxide-0.10.0-x86_64-unknown-linux-musl.tar.gz` | `2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae` | digest |
| eza | 0.23.5 | `eza-community/eza/releases/download/v0.23.5/eza_x86_64-unknown-linux-musl.tar.gz` | `e06eebab74b73d6b7d51a796a353824b001bea82df077706382e100815d28904` | digest |
| bat | 0.26.1 | `sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz` | `0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191` | digest |
| delta (git-delta) | 0.20.1 | `dandavison/delta/releases/download/0.20.1/delta-0.20.1-x86_64-unknown-linux-musl.tar.gz` | `69dcb4043f55c29118f408c6efd30115e0a4e0a6709253343b8c8fa814ab4a31` | digest |
| uv (+uvx) | 0.12.24 | `astral-sh/uv/releases/download/0.12.24/uv-x86_64-unknown-linux-musl.tar.gz` | `48170bd200a5430298c18f3b264485a1f3a8605f01088277daf6e37633edf0f5` | file |
| ripgrep (rg) | 15.2.0 | `BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-x86_64-unknown-linux-musl.tar.gz` | `33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c` | file |
| fd | 10.5.0 | `sharkdp/fd/releases/download/v10.5.0/fd-v10.5.0-x86_64-unknown-linux-musl.tar.gz` | `761c72dc8e120d85b22292063be8a796e2eeb20eb3e4f38b8fa2343ccf3514a7` | digest |
| lazygit | 0.66.0 | `jesseduffield/lazygit/releases/download/v0.66.0/lazygit_0.66.0_linux_x86_64.tar.gz` | `5b45541155d20bd32bf2cc5ab5b7e3d91c2eebf0fb1242281350edc27d59d2b7` | file |
| gh | 2.102.0 | `cli/cli/releases/download/v2.102.0/gh_2.102.0_linux_amd64.tar.gz` | `bb766f710eef8ede859c18578c72c327597cd4c8a85b06001b1f3843c6019386` | file |

fzf, lazygit and gh are Go binaries (statically linked); the rest are Rust musl
builds.

## Notes

- **uv**: previously a stand-alone `uv` 0.11.3 from the astral.sh installer
  lived directly in `~/.local/bin`; the script moved it (and `uvx`) to
  `~/.local/opt/backup/`. Upgrade uv by bumping the pin here, not with
  `uv self update` (the binary is now a symlink into `~/.local/opt`).
- **Not installed** (in the Mac Brewfile, but not needed or already present):
  `jq`, `tree`, `wget`, `git` come from RHEL; `btop`, `tldr`, `git-lfs`,
  `meld` are not installed (bashrc/gitconfig guard for them).
- Config files are linked by [`link-configs.sh`](link-configs.sh):
  `config/starship.toml` -> `~/.config/starship.toml`,
  `config/bat/config` -> `~/.config/bat/config`, `inputrc` -> `~/.inputrc`.
