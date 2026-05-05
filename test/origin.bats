#!/usr/bin/env bats

load test_helper

@test "fails with no arguments" {
  run barista-origin
  assert_failure
  assert_output "Usage: barista origin <command> [--nosystem]"
}

@test "prints path to executable in active version" {
  create_version "21.0.3"
  BARISTA_VERSION=21.0.3 run barista-origin java
  assert_success "${BARISTA_ROOT}/versions/21.0.3/bin/java"
}

@test "finds a non-java executable in the active version" {
  create_version "21.0.3"
  create_version_executable "21.0.3" "javac" "echo javac"
  BARISTA_VERSION=21.0.3 run barista-origin javac
  assert_success "${BARISTA_ROOT}/versions/21.0.3/bin/javac"
}

@test "fails when executable is not in the active version" {
  create_version "21.0.3"
  BARISTA_VERSION=21.0.3 run barista-origin no-such-tool
  assert_failure
  assert_output "barista: 'no-such-tool': not found in version '21.0.3'"
}

@test "searches system PATH for system version" {
  create_path_executable "java" "echo system-java"
  BARISTA_VERSION=system run barista-origin java
  assert_success "${BARISTA_TEST_DIR}/bin/java"
}

@test "fails for system version when executable is not in PATH" {
  BARISTA_VERSION=system run barista-origin no-such-tool
  assert_failure
  assert_output "barista: 'no-such-tool': not found in system PATH"
}

@test "--nosystem fails for system version" {
  create_path_executable "java" "echo system-java"
  BARISTA_VERSION=system run barista-origin java --nosystem
  assert_failure
  assert_output "barista: 'java': not found in any installed Java version"
}
