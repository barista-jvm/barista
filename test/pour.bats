#!/usr/bin/env bats

load test_helper

@test "fails with no arguments" {
  run barista-pour
  assert_failure
  assert_output "Usage: barista pour <command> [<args>...]"
}

@test "runs a command using the active version's bin/" {
  create_version_executable "21.0.3" "java" "echo poured-21"
  BARISTA_VERSION=21.0.3 run barista-pour java
  assert_success "poured-21"
}

@test "passes all arguments to the command" {
  create_version_executable "21.0.3" "java" 'printf "%s\n" "$@"'
  BARISTA_VERSION=21.0.3 run barista-pour java -jar app.jar --flag value
  assert_success
  assert_line "-jar"
  assert_line "app.jar"
  assert_line "--flag"
  assert_line "value"
}

@test "sets JAVA_HOME to the active version directory" {
  create_version_executable "21.0.3" "java" 'echo $JAVA_HOME'
  BARISTA_VERSION=21.0.3 run barista-pour java
  assert_success "${BARISTA_ROOT}/versions/21.0.3"
}

@test "active version bin/ is prepended to PATH" {
  create_version_executable "21.0.3" "java" 'echo "$PATH"'
  BARISTA_VERSION=21.0.3 run barista-pour java
  assert_success
  assert [ "${lines[0]}" = "${BARISTA_ROOT}/versions/21.0.3/bin:${PATH}" ]
}

@test "uses system PATH when version is system" {
  create_path_executable "java" 'echo system-java'
  BARISTA_VERSION=system run barista-pour java
  assert_success "system-java"
}

@test "fails when the active version directory does not exist" {
  BARISTA_VERSION=99.0.0 run barista-pour java
  assert_failure
  assert_output "barista: version '99.0.0' not installed"
}
