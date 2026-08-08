# --- functions ---------------------------------------------------------------

# mkcd — make a directory and step into it.
mkcd() { mkdir -p "$1" && cd "$1"; }

# extract — one command for every archive format.
extract() {
  local f="$1"
  [[ -f "$f" ]] || { print -u2 "extract: no such file: $f"; return 1; }
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
    *)  print -u2 "extract: don't know how to unpack $f"; return 1 ;;
  esac
}

# git-latexdiff <file> <n> — diff a .tex file against HEAD~n and open the PDF.
git-latexdiff() {
  if (( $# != 2 )); then
    print "usage: git-latexdiff <file.tex> <back-revision>"
    return 1
  fi
  if (( $2 < 0 )); then
    print -u2 "git-latexdiff: <back-revision> must be positive"
    return 1
  fi
  local dire based
  dire=$(dirname "$PWD/$1")
  based=$(git rev-parse --show-toplevel) || return 1
  git show "HEAD~$2:${dire#$based/}/$1" > "$1_diff.tmp" || return 1
  latexdiff "$1" "$1_diff.tmp" > "$1_diff.tex"
  pdflatex "$1_diff.tex"
  if [[ "$OSTYPE" == darwin* ]]; then
    open "$1_diff.pdf"
  else
    ${PDFVIEWER:-xdg-open} "$1_diff.pdf"
  fi
  rm -f "$1_diff".{tmp,tex,aux,log}
}

# scratch — a throwaway uv project in a temp dir, for trying a package out.
scratch() {
  local d
  d=$(mktemp -d "${TMPDIR:-/tmp}/scratch-XXXXXX") || return 1
  cd "$d" || return 1
  uv init --quiet .
  [[ $# -gt 0 ]] && uv add "$@"
  print "scratch project at $d"
}

# dotfiles-sync — pull the repo and re-link, in one go.
dotfiles-sync() {
  command git -C "$DOTFILES" pull --ff-only && "$DOTFILES/link.sh"
}
