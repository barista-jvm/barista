DIST_NAME="Eclipse Temurin (Adoptium)"
DIST_API="https://api.adoptium.net/v3"

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  printf '%s/binary/latest/%s/ga/%s/%s/jdk/hotspot/normal/eclipse' \
    "$DIST_API" "$feature_version" "$os" "$arch"
}

# Prints one version number per line, no headers or prose.
dist_list() {
  local releases flat
  releases="$(curl -sf "${DIST_API}/info/available_releases")" || {
    printf 'barista: failed to fetch version list from Adoptium\n' >&2
    return 1
  }
  flat="$(printf '%s' "$releases" | tr -d '\n')"
  printf '%s' "$flat" | grep -oE '"available_releases": *\[[^]]*\]' \
    | grep -oE '[0-9]+'
}
