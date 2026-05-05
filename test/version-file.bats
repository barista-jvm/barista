#!/usr/bin/env bats

load test_helper

_setup() {
  mkdir -p "${BARISTA_TEST_DIR}/project"
  cd "${BARISTA_TEST_DIR}/project"
}

@test "returns global version file when no .java-version exists" {
  run barista-version-file
  assert_success "${BARISTA_ROOT}/version"
}

@test "finds .java-version in the current directory" {
  touch .java-version
  run barista-version-file
  assert_success "${BARISTA_TEST_DIR}/project/.java-version"
}

@test "finds .java-version in a parent directory" {
  touch "${BARISTA_TEST_DIR}/.java-version"
  mkdir -p sub/dir
  cd sub/dir
  run barista-version-file
  assert_success "${BARISTA_TEST_DIR}/.java-version"
}

@test "prefers closer .java-version over a parent one" {
  touch "${BARISTA_TEST_DIR}/.java-version"
  touch .java-version
  run barista-version-file
  assert_success "${BARISTA_TEST_DIR}/project/.java-version"
}

@test "accepts a directory argument" {
  mkdir -p "${BARISTA_TEST_DIR}/other"
  touch "${BARISTA_TEST_DIR}/other/.java-version"
  run barista-version-file "${BARISTA_TEST_DIR}/other"
  assert_success "${BARISTA_TEST_DIR}/other/.java-version"
}

@test "returns global file when the given directory has no .java-version" {
  run barista-version-file "${BARISTA_TEST_DIR}/project"
  assert_success "${BARISTA_ROOT}/version"
}
