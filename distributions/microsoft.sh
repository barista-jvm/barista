DIST_NAME="Microsoft Build of OpenJDK"

_msft_os() {
  case "$1" in
    mac   ) echo "macos" ;;
    linux ) echo "linux" ;;
    *     ) echo "$1" ;;
  esac
}

_msft_arch() {
  case "$1" in
    x64     ) echo "x64" ;;
    aarch64 ) echo "aarch64" ;;
    *       ) echo "$1" ;;
  esac
}

dist_url() {
  local feature_version="$1" os="$2" arch="$3"
  local mos march
  mos="$(_msft_os "$os")"
  march="$(_msft_arch "$arch")"
  printf 'https://aka.ms/download-jdk/microsoft-jdk-%s-%s-%s.tar.gz' \
    "$feature_version" "$mos" "$march"
}

# Prints one version number per line, no headers or prose.
dist_list() {
  printf '%s\n' 11 17 21
}
