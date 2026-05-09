DIST_NAME="OpenJDK (jdk.java.net)"
ARCHIVE_URL="https://jdk.java.net/archive/"

_openjdk_os() {
  case "$1" in
    mac   ) echo "macos" ;;
    linux ) echo "linux" ;;
    *     ) echo "$1" ;;
  esac
}

# Fetch the archive page and return its content, or fail.
_openjdk_page() {
  curl -sf "$ARCHIVE_URL" || {
    printf 'barista: failed to fetch OpenJDK archive index\n' >&2
    return 1
  }
}

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  local jdk_os page url

  jdk_os="$(_openjdk_os "$os")"
  page="$(_openjdk_page)" || return 1

  # The archive page lists all .tar.gz hrefs ordered newest-first.
  # Match openjdk-{major}_ (GA release) or openjdk-{major}. (patch release)
  # then narrow by OS token and arch; head -1 gives the latest patch.
  url="$(printf '%s' "$page" \
    | grep -oE 'https://download\.java\.net[^"]*\.tar\.gz' \
    | grep "openjdk-${feature_version}[_.][^_]*_${jdk_os}-${arch}_bin\.tar\.gz" \
    | head -1)"

  # Older macOS releases used "osx" instead of "macos"
  if [ -z "$url" ] && [ "$os" = "mac" ]; then
    url="$(printf '%s' "$page" \
      | grep -oE 'https://download\.java\.net[^"]*\.tar\.gz' \
      | grep "openjdk-${feature_version}[_.][^_]*_osx-${arch}_bin\.tar\.gz" \
      | head -1)"
  fi

  if [ -z "$url" ]; then
    printf 'barista: no OpenJDK build found for Java %s on %s/%s\n' \
      "$feature_version" "$os" "$arch" >&2
    printf 'barista: see %s for available builds\n' "$ARCHIVE_URL" >&2
    return 1
  fi

  printf '%s' "$url"
}

dist_resolve_alias() {
  case "$1" in
  latest )
    dist_list 2>/dev/null | head -1 | awk -F. '{print $1}'
    ;;
  lts )
    printf 'barista: OpenJDK (jdk.java.net) does not publish LTS releases\n' >&2
    return 1
    ;;
  * ) printf 'barista: unknown alias: %s\n' "$1" >&2; return 1 ;;
  esac
}

# Prints one version string per line (latest patch for each major), no prose.
# Versions are scraped live from the archive page.
dist_list() {
  local page
  page="$(_openjdk_page)" || return 1

  # Extract versions from linux-x64 filenames (universally available across
  # all archive entries). Page is ordered newest-first; awk keeps the first
  # (latest) occurrence per major version number.
  printf '%s' "$page" \
    | grep -oE 'openjdk-[0-9][^_]*_linux-x64_bin\.tar\.gz' \
    | sed 's/openjdk-//;s/_linux-x64_bin\.tar\.gz//' \
    | awk -F. '!seen[$1]++'
}
