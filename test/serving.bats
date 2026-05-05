#!/usr/bin/env bats

load test_helper

_setup() {
  mkdir -p "$BARISTA_ROOT"
  cd "$BARISTA_TEST_DIR"
}

@test "falls back to system when nothing is set" {
  run barista-serving
  assert_success "system (set by default (system))"
}

@test "--bare prints just the version name" {
  run barista-serving --bare
  assert_success "system"
}

@test "BARISTA_VERSION env var takes highest priority" {
  create_version "21.0.3"
  BARISTA_VERSION=21.0.3 run barista-serving
  assert_success "21.0.3 (set by BARISTA_VERSION environment variable)"
}

@test "--bare with BARISTA_VERSION" {
  create_version "21.0.3"
  BARISTA_VERSION=21.0.3 run barista-serving --bare
  assert_success "21.0.3"
}

@test "local .java-version file is used when no env var" {
  create_version "17.0.9"
  echo "17.0.9" > "${BARISTA_TEST_DIR}/.java-version"
  cd "$BARISTA_TEST_DIR"
  run barista-serving
  assert_success "17.0.9 (set by ${BARISTA_TEST_DIR}/.java-version)"
}

@test "global version file is used when no env var or local file" {
  create_version "21.0.3"
  echo "21.0.3" > "${BARISTA_ROOT}/version"
  run barista-serving
  assert_success "21.0.3 (set by ${BARISTA_ROOT}/version)"
}

@test "BARISTA_VERSION overrides local .java-version" {
  create_version "21.0.3"
  create_version "17.0.9"
  echo "17.0.9" > "${BARISTA_TEST_DIR}/.java-version"
  BARISTA_VERSION=21.0.3 run barista-serving
  assert_success "21.0.3 (set by BARISTA_VERSION environment variable)"
}

@test "BARISTA_VERSION overrides global version file" {
  create_version "21.0.3"
  create_version "17.0.9"
  echo "17.0.9" > "${BARISTA_ROOT}/version"
  BARISTA_VERSION=21.0.3 run barista-serving
  assert_success "21.0.3 (set by BARISTA_VERSION environment variable)"
}

@test "local .java-version overrides global version file" {
  create_version "21.0.3"
  create_version "17.0.9"
  echo "17.0.9" > "${BARISTA_ROOT}/version"
  echo "21.0.3" > "${BARISTA_TEST_DIR}/.java-version"
  cd "$BARISTA_TEST_DIR"
  run barista-serving
  assert_success "21.0.3 (set by ${BARISTA_TEST_DIR}/.java-version)"
}

@test "walks up directory tree to find .java-version" {
  create_version "11.0.21"
  echo "11.0.21" > "${BARISTA_TEST_DIR}/.java-version"
  mkdir -p "${BARISTA_TEST_DIR}/project/subdir"
  cd "${BARISTA_TEST_DIR}/project/subdir"
  run barista-serving
  assert_success "11.0.21 (set by ${BARISTA_TEST_DIR}/.java-version)"
}

@test "ignores blank lines and comments in version file" {
  create_version "21.0.3"
  printf '# comment\n\n21.0.3\n' > "${BARISTA_ROOT}/version"
  run barista-serving
  assert_success "21.0.3 (set by ${BARISTA_ROOT}/version)"
}
