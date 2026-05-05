#!/usr/bin/env bats

load test_helper

_setup() {
  mkdir -p "$BARISTA_ROOT"
  cd "$BARISTA_TEST_DIR"
}

@test "shows placeholder when no versions are installed" {
  run barista-menu
  assert_success "  (no Java versions installed)"
}

@test "--bare prints nothing when no versions are installed" {
  run barista-menu --bare
  assert_success ""
}

@test "lists installed versions" {
  create_version "17.0.9"
  create_version "21.0.3"
  run barista-menu --bare
  assert_success
  assert_line "17.0.9"
  assert_line "21.0.3"
}

@test "marks the active version with an asterisk" {
  create_version "17.0.9"
  create_version "21.0.3"
  echo "21.0.3" > "${BARISTA_ROOT}/version"
  run barista-menu
  assert_success
  assert_line "  17.0.9"
  assert_line "* 21.0.3 (set by ${BARISTA_ROOT}/version)"
}

@test "active version driven by BARISTA_VERSION env var" {
  create_version "17.0.9"
  create_version "21.0.3"
  BARISTA_VERSION=17.0.9 run barista-menu
  assert_success
  assert_line "* 17.0.9 (set by BARISTA_VERSION environment variable)"
  assert_line "  21.0.3"
}

@test "active version driven by local .java-version" {
  create_version "21.0.3"
  echo "21.0.3" > "${BARISTA_TEST_DIR}/.java-version"
  run barista-menu
  assert_success
  assert_line "* 21.0.3 (set by ${BARISTA_TEST_DIR}/.java-version)"
}

@test "--bare lists only names, no active marker" {
  create_version "17.0.9"
  create_version "21.0.3"
  echo "21.0.3" > "${BARISTA_ROOT}/version"
  run barista-menu --bare
  assert_success
  assert_line "17.0.9"
  assert_line "21.0.3"
  refute_line "* 21.0.3"
}

@test "--skip-aliases omits symlinked versions" {
  create_version "21.0.3"
  ln -s "${BARISTA_ROOT}/versions/21.0.3" "${BARISTA_ROOT}/versions/21"
  run barista-menu --skip-aliases --bare
  assert_success
  assert_line "21.0.3"
  refute_line "21"
}
