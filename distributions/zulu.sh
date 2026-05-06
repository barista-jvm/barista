DIST_NAME="Azul Zulu"
DIST_API="https://api.azul.com/zulu/download/community/v1.0"

# Zulu uses different OS/arch tokens
_zulu_os() {
  case "$1" in
    mac   ) echo "macos" ;;
    linux ) echo "linux" ;;
    *     ) echo "$1" ;;
  esac
}

_zulu_arch() {
  case "$1" in
    x64     ) echo "x86_64" ;;
    aarch64 ) echo "aarch64" ;;
    *       ) echo "$1" ;;
  esac
}

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  local zos zarch bundle_info url
  zos="$(_zulu_os "$os")"
  zarch="$(_zulu_arch "$arch")"

  bundle_info="$(curl -sf \
    "${DIST_API}/bundles/latest/?jdk_version=${feature_version}&bundle_type=jdk&ext=tar.gz&os=${zos}&arch=${zarch}&hw_bitness=64")" || {
    printf 'barista: failed to resolve Zulu download URL\n' >&2
    return 1
  }

  url="$(printf '%s' "$bundle_info" | grep -o '"url":"[^"]*"' | sed 's/"url":"//;s/"//')"
  if [ -z "$url" ]; then
    printf 'barista: Zulu bundle not found for Java %s on %s/%s\n' \
      "$feature_version" "$os" "$arch" >&2
    return 1
  fi
  printf '%s' "$url"
}

# Prints one version number per line, no headers or prose.
dist_list() {
  local bundles
  bundles="$(curl -sf "${DIST_API}/bundles/?bundle_type=jdk&ext=tar.gz&javafx=false")" || {
    printf 'barista: failed to fetch Zulu version list\n' >&2
    return 1
  }
  printf '%s' "$bundles" \
    | grep -oE '"jdk_version":\[[0-9]+' \
    | grep -oE '[0-9]+$' \
    | sort -un
}
