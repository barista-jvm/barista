DIST_NAME="Microsoft Build of OpenJDK"
DOWNLOAD_PAGE="https://learn.microsoft.com/en-ca/java/openjdk/download"

_msft_os() {
  case "$1" in
    mac   ) echo "macos" ;;
    linux ) echo "linux" ;;
    *     ) echo "$1" ;;
  esac
}

_msft_page() {
  curl -sf "$DOWNLOAD_PAGE" || {
    printf 'barista: failed to fetch Microsoft JDK download page\n' >&2
    return 1
  }
}

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  local msft_os page candidates url

  msft_os="$(_msft_os "$os")"
  page="$(_msft_page)" || return 1

  # Collect all matching .tar.gz links for this major/os/arch.
  # The page excludes debug-symbol packages and uses lowercase OS tokens for
  # current releases; the legacy bare-major macOS link uses uppercase "macOS"
  # so it is naturally excluded when we search for lowercase "macos".
  candidates="$(printf '%s' "$page" \
    | grep -oE 'https://aka\.ms/download-jdk/microsoft-jdk-[0-9][^"'\'' >]*\.tar\.gz' \
    | grep -v 'debugsymbols' \
    | grep -- "-${msft_os}-${arch}\.tar\.gz" \
    | grep -- "microsoft-jdk-${feature_version}[.-]" \
    | sort -u)"

  # Prefer the patch release (e.g. 21.0.11) over a bare major (e.g. 21)
  url="$(printf '%s' "$candidates" | grep -- "microsoft-jdk-${feature_version}\." | head -1)"
  [ -z "$url" ] && url="$(printf '%s' "$candidates" | head -1)"

  if [ -z "$url" ]; then
    printf 'barista: no Microsoft JDK build found for Java %s on %s/%s\n' \
      "$feature_version" "$os" "$arch" >&2
    return 1
  fi
  printf '%s' "$url"
}

# Prints one version string per line (latest patch for each major), no prose.
# Versions are scraped live from the Microsoft download page.
dist_list() {
  local page
  page="$(_msft_page)" || return 1

  # linux-x64 links appear newest-first on the page; awk keeps the first
  # (latest) per major. uniq collapses the duplicate hrefs the page emits.
  printf '%s' "$page" \
    | grep -oE 'https://aka\.ms/download-jdk/microsoft-jdk-[0-9][^"'\'' >]*-linux-x64\.tar\.gz' \
    | grep -v 'debugsymbols' \
    | grep -oE 'microsoft-jdk-[0-9][^-]+' \
    | sed 's/microsoft-jdk-//' \
    | uniq \
    | awk -F. '!seen[$1]++'
}
