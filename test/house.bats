#!/usr/bin/env bats

load test_helper

@test "defaults to system when no global version is set" {
  run barista-house
  assert_success "system"
}

@test "reads the existing global version file" {
  mkdir -p "$BARISTA_ROOT"
  echo "21.0.3" > "${BARISTA_ROOT}/version"
  run barista-house
  assert_success "21.0.3"
}

@test "sets the global version" {
  create_version "21.0.3"
  run barista-house 21.0.3
  assert_success ""
  run barista-house
  assert_success "21.0.3"
}

@test "global version file contains the written version" {
  create_version "17.0.9"
  run barista-house 17.0.9
  assert_success
  assert [ "$(cat "${BARISTA_ROOT}/version")" = "17.0.9" ]
}

@test "fails when setting a version that is not installed" {
  mkdir -p "$BARISTA_ROOT"
  run barista-house 99.0.0
  assert_failure
  assert_line "barista: version '99.0.0' not installed"
}

@test "sets global version to system" {
  run barista-house system
  assert_success ""
  run barista-house
  assert_success "system"
}

@test "overwrites an existing global version" {
  create_version "17.0.9"
  create_version "21.0.3"
  barista-house 17.0.9
  run barista-house 21.0.3
  assert_success ""
  run barista-house
  assert_success "21.0.3"
}
