# Functions shared by zsh and bash.
#
# Same rule as shell/aliases.sh: valid in both shells and in bash 3.2.
# `printf` not `print`, `${1}_x` not `$1_x`, no zsh glob qualifiers.

# mkcd — make a directory and step into it.
mkcd() { mkdir -p "$1" && cd "$1"; }

# extract — one command for every archive format.
extract() {
  local f="$1"
  [ -f "$f" ] || { printf 'extract: no such file: %s\n' "$f" >&2; return 1; }
  case "$f" in
    *.tar.bz2|*.tbz2) tar xjf "$f"   ;;
    *.tar.gz|*.tgz)   tar xzf "$f"   ;;
    *.tar.xz)         tar xJf "$f"   ;;
    *.tar)            tar xf  "$f"   ;;
    *.bz2)            bunzip2 "$f"   ;;
    *.gz)             gunzip  "$f"   ;;
    *.zip)            unzip   "$f"   ;;
    *.7z)             7z x    "$f"   ;;
    *.rar)            unrar x "$f"   ;;
    *) printf "extract: don't know how to unpack %s\n" "$f" >&2; return 1 ;;
  esac
}

# git-latexdiff <file.tex> <n> — diff against HEAD~n and open the result.
git-latexdiff() {
  if [ "$#" -ne 2 ]; then
    printf 'usage: git-latexdiff <file.tex> <back-revision>\n'
    return 1
  fi
  if [ "$2" -lt 0 ]; then
    printf 'git-latexdiff: <back-revision> must be positive\n' >&2
    return 1
  fi
  local dire based
  dire=$(dirname "$PWD/$1")
  based=$(git rev-parse --show-toplevel) || return 1
  git show "HEAD~$2:${dire#"$based"/}/$1" > "${1}_diff.tmp" || return 1
  latexdiff "$1" "${1}_diff.tmp" > "${1}_diff.tex"
  pdflatex "${1}_diff.tex"
  case "$OSTYPE" in
    darwin*) open "${1}_diff.pdf" ;;
    *)       ${PDFVIEWER:-xdg-open} "${1}_diff.pdf" ;;
  esac
  rm -f "${1}_diff.tmp" "${1}_diff.tex" "${1}_diff.aux" "${1}_diff.log"
}

# scratch — a throwaway uv project in a temp dir, for trying a package out.
scratch() {
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/scratch-XXXXXX") || return 1
  cd "$d" || return 1
  uv init --quiet .
  [ "$#" -gt 0 ] && uv add "$@"
  printf 'scratch project at %s\n' "$d"
}

# dotfiles-sync — pull the repo and re-link, in one go.
dotfiles-sync() {
  command git -C "$DOTFILES" pull --ff-only && "$DOTFILES/link.sh"
}

# --- carried over from the Linux setup --------------------------------------

# diff — use git's formatting (and delta, if configured) for ad-hoc diffs.
# "$@" is quoted here; the Linux original used bare $@ and broke on paths
# containing spaces.
diff() { git diff --no-index "$@"; }

# version — report what this OS actually is, whatever the OS is.
version() {
  command -v sw_vers    > /dev/null 2>&1 && sw_vers
  [ -r /proc/version ]  && cat /proc/version
  command -v lsb_release > /dev/null 2>&1 && lsb_release -a 2> /dev/null
  [ -r /etc/redhat-release ] && cat /etc/redhat-release
  return 0
}
