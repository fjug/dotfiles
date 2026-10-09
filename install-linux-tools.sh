#!/usr/bin/env bash
# install-linux-tools.sh — user-level CLI tools for a Linux box without root
# (RHEL VDI, HPC login node). Mirrors the Mac's Brewfile "modern CLI core".
#
# Every tool is a static (musl) or self-contained x86_64 release binary from
# the project's official GitHub releases, pinned to a version and SHA-256.
# Releases are unpacked into ~/.local/opt/<tool>-<version>/ and the binaries
# are symlinked into ~/.local/bin. Bash completions and man pages shipped in
# the archives are linked into ~/.local/share/{bash-completion/completions,man}.
#
# Idempotent: an already-installed, verified version is not downloaded again;
# links are (re)pointed every run. Nothing touches shell rc files.
# A pre-existing *real file* in ~/.local/bin is moved to ~/.local/opt/backup/.
#
# Usage: ./install-linux-tools.sh [tool ...]   (default: all)
# To upgrade: bump version/url/sha256 below (see linux-tools.md) and re-run.

set -euo pipefail

BIN="$HOME/.local/bin"
OPT="$HOME/.local/opt"
BCD="${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions"
MAN1="${XDG_DATA_HOME:-$HOME/.local/share}/man/man1"
GH=https://github.com

case "$(uname -s)-$(uname -m)" in
	Linux-x86_64) ;;
	*) echo "install-linux-tools: only Linux x86_64 is pinned here" >&2; exit 1 ;;
esac

# name | version | url | sha256 | binaries (comma-separated)
TOOLS=(
"starship|1.26.0|$GH/starship/starship/releases/download/v1.26.0/starship-x86_64-unknown-linux-musl.tar.gz|b7c232b0e8249d8e55a40beb79c5c43a7d370f3f9408bd215deb0170daeaadf3|starship"
"fzf|0.74.4|$GH/junegunn/fzf/releases/download/v0.74.4/fzf-0.74.4-linux_amd64.tar.gz|05e6813a337cc722c3ed07e54a764b75cc5d671e2e60459db0ba696ee5fa7504|fzf"
"zoxide|0.10.0|$GH/ajeetdsouza/zoxide/releases/download/v0.10.0/zoxide-0.10.0-x86_64-unknown-linux-musl.tar.gz|2d93385b99f3e82cf2701609a1bffcad863fbeb75aa3fe7eb6be4d29be68b1ae|zoxide"
"eza|0.23.5|$GH/eza-community/eza/releases/download/v0.23.5/eza_x86_64-unknown-linux-musl.tar.gz|e06eebab74b73d6b7d51a796a353824b001bea82df077706382e100815d28904|eza"
"bat|0.26.1|$GH/sharkdp/bat/releases/download/v0.26.1/bat-v0.26.1-x86_64-unknown-linux-musl.tar.gz|0dcd8ac79732c0d5b136f11f4ee00e581440e16a44eab5b3105b611bbf2cf191|bat"
"delta|0.20.1|$GH/dandavison/delta/releases/download/0.20.1/delta-0.20.1-x86_64-unknown-linux-musl.tar.gz|69dcb4043f55c29118f408c6efd30115e0a4e0a6709253343b8c8fa814ab4a31|delta"
"uv|0.12.24|$GH/astral-sh/uv/releases/download/0.12.24/uv-x86_64-unknown-linux-musl.tar.gz|48170bd200a5430298c18f3b264485a1f3a8605f01088277daf6e37633edf0f5|uv,uvx"
"ripgrep|15.2.0|$GH/BurntSushi/ripgrep/releases/download/15.2.0/ripgrep-15.2.0-x86_64-unknown-linux-musl.tar.gz|33e15bcf1624b25cdd2a55813a47a2f95dbe126268203e76aa6a585d1e7b149c|rg"
"fd|10.5.0|$GH/sharkdp/fd/releases/download/v10.5.0/fd-v10.5.0-x86_64-unknown-linux-musl.tar.gz|761c72dc8e120d85b22292063be8a796e2eeb20eb3e4f38b8fa2343ccf3514a7|fd"
"lazygit|0.66.0|$GH/jesseduffield/lazygit/releases/download/v0.66.0/lazygit_0.66.0_linux_x86_64.tar.gz|5b45541155d20bd32bf2cc5ab5b7e3d91c2eebf0fb1242281350edc27d59d2b7|lazygit"
"gh|2.102.0|$GH/cli/cli/releases/download/v2.102.0/gh_2.102.0_linux_amd64.tar.gz|bb766f710eef8ede859c18578c72c327597cd4c8a85b06001b1f3843c6019386|gh"
)

STAMP=$(date +%Y%m%dT%H%M%S)
TMP=$(mktemp -d "${TMPDIR:-/tmp}/install-linux-tools.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$BIN" "$OPT" "$BCD" "$MAN1"

say() { printf '%s\n' "$*"; }

# link <target> <link>: symlink, moving a real file out of the way first
link() {
	local target="$1" lnk="$2"
	if [ -e "$lnk" ] && [ ! -L "$lnk" ]; then
		mkdir -p "$OPT/backup"
		mv "$lnk" "$OPT/backup/$(basename "$lnk").$STAMP"
		say "  backed up $lnk -> $OPT/backup/$(basename "$lnk").$STAMP"
	fi
	[ "$(readlink "$lnk" 2> /dev/null)" = "$target" ] || ln -sfn "$target" "$lnk"
}

install_one() {
	local name="$1" version="$2" url="$3" sha="$4" bins="$5"
	local dest="$OPT/$name-$version" file="$TMP/${url##*/}" b src

	if [ -f "$dest/.sha256" ] && [ "$(cat "$dest/.sha256")" = "$sha" ]; then
		say "$name $version: already installed"
	else
		say "$name $version: downloading ${url##*/}"
		curl -fsSL --retry 3 -o "$file" "$url"
		echo "$sha  $file" | sha256sum -c --quiet - || {
			echo "$name: SHA-256 mismatch, aborting" >&2
			return 1
		}
		rm -rf "$dest.partial" && mkdir -p "$dest.partial"
		tar -xzf "$file" -C "$dest.partial" --no-same-owner
		echo "$sha" > "$dest.partial/.sha256"
		rm -rf "$dest" && mv "$dest.partial" "$dest"
	fi

	for b in ${bins//,/ }; do
		src=$(find "$dest" -type f -name "$b" -perm -u+x | head -n 1)
		[ -n "$src" ] || { echo "$name: binary '$b' not found in $dest" >&2; return 1; }
		link "$src" "$BIN/$b"
	done

	# bash completions and man pages shipped in the archive, if any
	while IFS= read -r src; do
		b=$(basename "$src"); b=${b%.bash}; b=${b%.bash-completion}
		link "$src" "$BCD/$b"
	done < <(find "$dest" -type f \( -name '*.bash' -o -name '*.bash-completion' \) \
		! -name 'key-bindings.bash' ! -name 'completion.bash' 2> /dev/null)
	while IFS= read -r src; do
		link "$src" "$MAN1/$(basename "$src")"
	done < <(find "$dest" -type f -name '*.1' 2> /dev/null)
}

want=" ${*:-} "
for row in "${TOOLS[@]}"; do
	IFS='|' read -r name version url sha bins <<< "$row"
	[ "$want" = "  " ] || [[ "$want" == *" $name "* ]] || continue
	install_one "$name" "$version" "$url" "$sha" "$bins"
done

# Completions for tools that generate them rather than ship them; written to
# files so bash-completion lazy-loads them instead of costing startup time.
gen() { command -v "$1" > /dev/null 2>&1 && "${@:2}" > "$BCD/$1.tmp" 2> /dev/null && mv "$BCD/$1.tmp" "$BCD/$1" || rm -f "$BCD/$1.tmp"; }
gen gh       "$BIN/gh" completion -s bash
gen delta    "$BIN/delta" --generate-completion bash
gen starship "$BIN/starship" completions bash
gen uv       "$BIN/uv" generate-shell-completion bash
gen uvx      "$BIN/uvx" --generate-shell-completion bash

say "done. Versions:"
for b in starship fzf zoxide eza bat delta uv rg fd lazygit gh; do
	[ -x "$BIN/$b" ] && printf '  %-9s %s\n' "$b" "$("$BIN/$b" --version 2> /dev/null | grep -m 1 -oE '[0-9]+\.[0-9]+\.[0-9]+')"
done
