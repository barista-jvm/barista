#!/usr/bin/env bats

load test_helper

@test "prints the prefix for the active version" {
  create_version "21.0.3"
  BARISTA_VERSION=21.0.3 run barista-counter
  assert_success "${BARISTA_ROOT}/versions/21.0.3"
}

@test "accepts an explicit version argument" {
  create_version "17.0.9"
  run barista-counter 17.0.9
  assert_success "${BARISTA_ROOT}/versions/17.0.9"
}

@test "accepts multiple version arguments" {
  create_version "17.0.9"
  create_version "21.0.3"
  run barista-counter 17.0.9 21.0.3
  assert_success
  assert_line "${BARISTA_ROOT}/versions/17.0.9"
  assert_line "${BARISTA_ROOT}/versions/21.0.3"
}

@test "fails for a version that is not installed" {
  run barista-counter 99.0.0
  assert_failure
  assert_output "barista: version '99.0.0' not installed"
}

@test "falls back to active version when no argument is given" {
  create_version "21.0.3"
  echo "21.0.3" > "${BARISTA_ROOT}/version"
  run barista-counter
  assert_success "${BARISTA_ROOT}/versions/21.0.3"
}
