#!/usr/bin/env bats

load test_helper

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Create a stub distribution in BARISTA_ROOT/distributions/.
# Usage: create_stub_dist <name> [with_alias_support]
create_stub_dist() {
  local name="$1" with_alias="${2:-}"
  local dir="${BARISTA_ROOT}/distributions"
  mkdir -p "$dir"
  {
    echo "DIST_NAME=\"Stub ${name}\""
    echo "dist_url() { printf 'https://example.com/jdk-%s-%s-%s.tar.gz' \"\$1\" \"\$2\" \"\$3\"; }"
    echo "dist_list() { printf '%s\n' 17 21; }"
    if [ -n "$with_alias" ]; then
      echo 'dist_resolve_alias() {'
      echo '  case "$1" in'
      echo '  lts    ) echo "17" ;;'
      echo '  latest ) echo "21" ;;'
      echo '  *      ) return 1 ;;'
      echo '  esac'
      echo '}'
    fi
  } > "${dir}/${name}.sh"
}

# Create a minimal .tar.gz containing bin/java, suitable for installation.
create_stub_archive() {
  local archive="$1"
  local staging
  staging="$(mktemp -d)"
  mkdir -p "${staging}/bin"
  printf '#!/bin/sh\necho stub-java\n' > "${staging}/bin/java"
  chmod +x "${staging}/bin/java"
  tar -czf "$archive" -C "$staging" .
  rm -rf "$staging"
}

# Create a stub distribution that serves a real archive + checksum via file://.
# Usage: create_checksum_dist <name> <archive_path> <checksum_path>
create_checksum_dist() {
  local name="$1" archive="$2" checksum="$3"
  local dir="${BARISTA_ROOT}/distributions"
  mkdir -p "$dir"
  {
    printf 'DIST_NAME="Stub %s"\n' "$name"
    printf "dist_url() { printf 'file://%s'; }\n" "$archive"
    printf "dist_checksum_url() { printf 'file://%s'; }\n" "$checksum"
    printf 'dist_list() { printf "21\n"; }\n'
  } > "${dir}/${name}.sh"
}

@test "--version prints barista-brew version" {
  run barista-brew --version
  assert_success
  assert_line "barista-brew ${BARISTA_VERSION_STRING}"
}

@test "fails with no arguments" {
  run barista-brew
  assert_failure
  assert_line "Usage: barista brew <dist>@<version>"
}

@test "fails when the version is already installed and --force is not given" {
  create_version "adoptium@21.0.3"
  run barista-brew adoptium@21.0.3
  assert_failure
  assert_line "barista: adoptium@21.0.3 is already brewed at ${BARISTA_ROOT}/versions/adoptium@21.0.3"
}

@test "--force flag is accepted for an already-installed version" {
  # We can't actually download, so just verify the flag is parsed correctly.
  # With --force the script proceeds past the "already installed" guard and
  # fails at download (no network in tests), not at the guard check.
  create_version "adoptium@21.0.3"
  run barista-brew --force adoptium@21.0.3
  # Should NOT produce the "already brewed" error
  refute_line "barista: adoptium@21.0.3 is already brewed at ${BARISTA_ROOT}/versions/adoptium@21.0.3"
}

# ---------------------------------------------------------------------------
# @lts / @latest alias resolution
# ---------------------------------------------------------------------------

@test "@lts resolves via dist_resolve_alias and prints the resolved version" {
  create_stub_dist "stubdist" with_alias
  run barista-brew stubdist@lts
  # Alias resolves to 17; script proceeds to download (fails without network)
  # but must have printed the "Brewing Java 17" header first
  assert_line "==> Brewing Java 17 (feature release 17)"
}

@test "@latest resolves via dist_resolve_alias and prints the resolved version" {
  create_stub_dist "stubdist" with_alias
  run barista-brew stubdist@latest
  assert_line "==> Brewing Java 21 (feature release 21)"
}

@test "@latest falls back to dist_list when dist_resolve_alias is not defined" {
  create_stub_dist "stubdist"  # no alias support; dist_list returns 17 and 21
  run barista-brew stubdist@latest
  # Generic fallback picks the numerically highest entry from dist_list (21)
  assert_line "==> Brewing Java 21 (feature release 21)"
}

@test "@lts without dist_resolve_alias exits with a helpful error" {
  create_stub_dist "stubdist"  # no alias support
  run barista-brew stubdist@lts
  assert_failure
  assert_line "barista: distribution 'stubdist' does not support @lts"
}

# ---------------------------------------------------------------------------
# SHA256 checksum verification
# ---------------------------------------------------------------------------

@test "checksum verification is skipped when dist_checksum_url is not defined" {
  create_stub_dist "stubdist"
  run barista-brew stubdist@21
  # Download fails (fake URL) but no checksum error — skip path taken silently
  refute_line "barista: could not fetch checksum"
  refute_line "barista: SHA256 checksum mismatch!"
}

@test "checksum verification passes and prints 'Checksum OK'" {
  local archive="${BATS_TEST_TMPDIR}/test.tar.gz"
  local checkfile="${BATS_TEST_TMPDIR}/test.sha256"
  create_stub_archive "$archive"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$archive" | cut -d' ' -f1 > "$checkfile"
  else
    shasum -a 256 "$archive" | cut -d' ' -f1 > "$checkfile"
  fi
  create_checksum_dist "cdist" "$archive" "$checkfile"
  run barista-brew cdist@21
  assert_line "    Checksum OK"
}

@test "checksum mismatch exits with an error" {
  local archive="${BATS_TEST_TMPDIR}/test.tar.gz"
  local checkfile="${BATS_TEST_TMPDIR}/bad.sha256"
  create_stub_archive "$archive"
  printf '%s\n' "0000000000000000000000000000000000000000000000000000000000000000" > "$checkfile"
  create_checksum_dist "cdist" "$archive" "$checkfile"
  run barista-brew cdist@21
  assert_failure
  assert_line "barista: SHA256 checksum mismatch!"
}

@test "unreachable checksum URL exits with an error" {
  local archive="${BATS_TEST_TMPDIR}/test.tar.gz"
  local checkfile="${BATS_TEST_TMPDIR}/missing.sha256"
  create_stub_archive "$archive"
  # checkfile does not exist — curl -sf on file:// of a missing path returns empty
  local dir="${BARISTA_ROOT}/distributions"
  mkdir -p "$dir"
  {
    printf 'DIST_NAME="Stub cdist"\n'
    printf "dist_url() { printf 'file://%s'; }\n" "$archive"
    printf "dist_checksum_url() { printf 'file://%s'; }\n" "$checkfile"
    printf 'dist_list() { printf "21\n"; }\n'
  } > "${dir}/cdist.sh"
  run barista-brew cdist@21
  assert_failure
  assert_line "barista: could not fetch checksum from file://${checkfile}"
}
