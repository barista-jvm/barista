#!/usr/bin/env bats

load test_helper

@test "fails with no arguments" {
  run barista-discard
  assert_failure
  assert_output "Usage: barista discard <version>"
}

@test "fails when the version is not installed" {
  run barista-discard 99.0.0
  assert_failure
  assert_output "barista: version '99.0.0' is not installed"
}

@test "--force silently succeeds for a missing version" {
  run barista-discard --force 99.0.0
  assert_success ""
}

@test "--force removes the version directory without prompting" {
  create_version "17.0.9"
  assert [ -d "${BARISTA_ROOT}/versions/17.0.9" ]
  run barista-discard --force 17.0.9
  assert_success
  assert [ ! -d "${BARISTA_ROOT}/versions/17.0.9" ]
}

@test "reports success after removal" {
  create_version "17.0.9"
  run barista-discard --force 17.0.9
  assert_success
  assert_line "Java 17.0.9 has been discarded."
}

@test "triggers a restock after removal" {
  create_version "17.0.9"
  create_version "21.0.3"
  barista-restock
  assert [ -x "${BARISTA_ROOT}/shims/java" ]
  run barista-discard --force 17.0.9
  assert_success
  # Shim for java still exists because 21.0.3 also has java
  assert [ -x "${BARISTA_ROOT}/shims/java" ]
}
