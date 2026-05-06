DIST_NAME="Amazon Corretto"
DIST_BASE="https://corretto.aws/downloads/latest"

# Corretto uses different OS/arch tokens than Adoptium
_corretto_os() {
  case "$1" in
    mac   ) echo "macos" ;;
    linux ) echo "linux" ;;
    *     ) echo "$1" ;;
  esac
}

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  local cos
  cos="$(_corretto_os "$os")"
  printf '%s/amazon-corretto-%s-%s-%s-jdk.tar.gz' \
    "$DIST_BASE" "$feature_version" "$arch" "$cos"
}

# Prints one version number per line, no headers or prose.
dist_list() {
  printf '%s\n' 8 11 17 21 22 23 24
}
