unset BARISTA_VERSION

setup() {
  export _BARISTA_INSTALL_PREFIX="${BATS_TEST_DIRNAME%/*}"

  # Resolve BATS_TEST_TMPDIR through any symlinks so path comparisons are stable
  local tmpdir="${BATS_TEST_TMPDIR}"
  tmpdir="$(cd "$tmpdir" && pwd -P)"

  export BARISTA_TEST_DIR="${tmpdir}/barista"
  export BARISTA_ROOT="${BARISTA_TEST_DIR}/root"
  export HOME="${BARISTA_TEST_DIR}/home"

  # Minimal, controlled PATH: system utils + barista execs + test bin + shims
  PATH=/usr/bin:/bin:/usr/sbin:/sbin
  PATH="${BARISTA_TEST_DIR}/bin:$PATH"
  PATH="${_BARISTA_INSTALL_PREFIX}/execs:$PATH"
  PATH="${BARISTA_ROOT}/shims:$PATH"
  export PATH

  # Required by barista-help and barista-commands
  export BARISTA_DIR="${_BARISTA_INSTALL_PREFIX}"
  export BARISTA_VERSION_STRING
  BARISTA_VERSION_STRING="$(tr -d '[:space:]' < "${_BARISTA_INSTALL_PREFIX}/version.txt")"

  mkdir -p "${BARISTA_TEST_DIR}/bin"
  mkdir -p "$HOME"

  # If a test file defines _setup(), call it now
  if [ "$(type -t _setup)" = "function" ]; then
    _setup
  fi
}

# ---------------------------------------------------------------------------
# Assertion helpers (modelled on pyenv's test_helper)
# ---------------------------------------------------------------------------

flunk() {
  { if [ "$#" -eq 0 ]; then cat -
    else echo "$@"
    fi
  } | sed "s:${BARISTA_TEST_DIR}:TEST_DIR:g" >&2
  return 1
}

assert_success() {
  if [ "$status" -ne 0 ]; then
    flunk "command failed with exit status $status"$'\n'"output: $output"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_failure() {
  if [ "$status" -eq 0 ]; then
    flunk "expected failed exit status"$'\n'"output: $output"
  elif [ "$#" -gt 0 ]; then
    assert_output "$1"
  fi
}

assert_equal() {
  if [ "$1" != "$2" ]; then
    { echo "expected: \`$1'"
      echo "actual:   \`$2'"
    } | flunk
  fi
}

assert_output() {
  local expected
  if [ $# -eq 0 ]; then expected="$(cat -)"
  else expected="$1"
  fi
  assert_equal "$expected" "$output"
}

assert_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    assert_equal "$2" "${lines[$1]}"
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then return 0; fi
    done
    flunk "expected line \`$1'"$'\n'"output: $output"
  fi
}

refute_line() {
  if [ "$1" -ge 0 ] 2>/dev/null; then
    local num_lines="${#lines[@]}"
    if [ "$1" -lt "$num_lines" ]; then
      flunk "output has $num_lines lines"
    fi
  else
    local line
    for line in "${lines[@]}"; do
      if [ "$line" = "$1" ]; then
        flunk "expected to not find line \`$line'"$'\n'"output: $output"
      fi
    done
  fi
}

assert() {
  if ! "$@"; then
    flunk "failed: $*"
  fi
}

# ---------------------------------------------------------------------------
# Fixture helpers
# ---------------------------------------------------------------------------

# Create a fake installed Java version with a minimal java executable
create_version() {
  local version="$1"
  local bin_dir="${BARISTA_ROOT}/versions/${version}/bin"
  mkdir -p "$bin_dir"
  {
    echo "#!/usr/bin/env bash"
    echo "echo \"openjdk ${version}\""
  } > "${bin_dir}/java"
  chmod +x "${bin_dir}/java"
}

# Create an arbitrary executable inside a version's bin/
create_version_executable() {
  local version="$1"
  local name="$2"
  shift 2
  local bin_dir="${BARISTA_ROOT}/versions/${version}/bin"
  mkdir -p "$bin_dir"
  if [ $# -eq 0 ]; then
    { echo "#!/usr/bin/env bash"; cat; } > "${bin_dir}/${name}"
  else
    { echo "#!/usr/bin/env bash"; printf '%s\n' "$@"; } > "${bin_dir}/${name}"
  fi
  chmod +x "${bin_dir}/${name}"
}

# Create an executable that appears on the test PATH (simulates system tools)
create_path_executable() {
  local name="$1"
  shift
  local bin_dir="${BARISTA_TEST_DIR}/bin"
  mkdir -p "$bin_dir"
  if [ $# -eq 0 ]; then
    { echo "#!/usr/bin/env bash"; cat; } > "${bin_dir}/${name}"
  else
    { echo "#!/usr/bin/env bash"; printf '%s\n' "$@"; } > "${bin_dir}/${name}"
  fi
  chmod +x "${bin_dir}/${name}"
}
