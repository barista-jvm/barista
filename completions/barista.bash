# Bash completion for barista

_barista_get_distributions() {
  local barista_dir="${BARISTA_DIR:-}"
  if [ -z "$barista_dir" ]; then
    local barista_bin
    barista_bin="$(command -v barista 2>/dev/null)" || return
    barista_dir="$(cd "$(dirname "$barista_bin")/.." && pwd)"
  fi
  local user_dir="${BARISTA_ROOT:-$HOME/.barista}/distributions"
  local builtin_dir="${barista_dir}/distributions"
  for dir in "$builtin_dir" "$user_dir"; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.sh; do
      [ -f "$f" ] && basename "$f" .sh
    done
  done | sort -u
}

_barista() {
  # Treat @ as a regular character so dist@version is one token
  local COMP_WORDBREAKS="${COMP_WORDBREAKS//@/}"
  COMPREPLY=()
  local cur="${COMP_WORDS[COMP_CWORD]}"

  local subcommands="brew commands counter discard help house menu origin pantry pour restock serving setup table version-file"

  if [ "$COMP_CWORD" -eq 1 ]; then
    COMPREPLY=($(compgen -W "$subcommands" -- "$cur"))
    return
  fi

  local subcmd="${COMP_WORDS[1]}"
  case "$subcmd" in
  house | table | discard )
    local versions
    versions="$(barista menu --bare 2>/dev/null) system"
    COMPREPLY=($(compgen -W "$versions" -- "$cur"))
    ;;
  brew )
    case "$cur" in
    *@* )
      local dist="${cur%%@*}"
      COMPREPLY=($(compgen -W "${dist}@lts ${dist}@latest" -- "$cur"))
      ;;
    * )
      local dists
      dists="$(_barista_get_distributions)"
      COMPREPLY=($(compgen -W "$dists" -S '@' -- "$cur"))
      compopt -o nospace 2>/dev/null
      ;;
    esac
    ;;
  esac
}

complete -F _barista barista
