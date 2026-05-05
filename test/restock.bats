#!/usr/bin/env bats

load test_helper

@test "creates shims directory when it does not exist" {
  create_version "21.0.3"
  run barista-restock
  assert_success
  assert [ -d "${BARISTA_ROOT}/shims" ]
}

@test "creates a shim for every executable in installed versions" {
  create_version "21.0.3"
  create_version_executable "21.0.3" "javac" "echo javac"
  create_version_executable "21.0.3" "jar"   "echo jar"
  run barista-restock
  assert_success
  assert [ -x "${BARISTA_ROOT}/shims/java" ]
  assert [ -x "${BARISTA_ROOT}/shims/javac" ]
  assert [ -x "${BARISTA_ROOT}/shims/jar" ]
}

@test "deduplicates executables across versions" {
  create_version "17.0.9"
  create_version "21.0.3"
  create_version_executable "17.0.9" "javac" "echo javac17"
  create_version_executable "21.0.3" "javac" "echo javac21"
  run barista-restock
  assert_success
  # Only one shim per name
  local count
  count="$(find "${BARISTA_ROOT}/shims" -name "javac" | wc -l | tr -d ' ')"
  assert_equal "1" "$count"
}

@test "removes stale shims before regenerating" {
  mkdir -p "${BARISTA_ROOT}/shims"
  touch "${BARISTA_ROOT}/shims/stale-tool"
  create_version "21.0.3"
  run barista-restock
  assert_success
  assert [ ! -e "${BARISTA_ROOT}/shims/stale-tool" ]
}

@test "reports the number of shims created" {
  create_version "21.0.3"
  create_version_executable "21.0.3" "javac" "echo javac"
  run barista-restock
  assert_success
  assert_line "barista: restocked 2 shim(s) in ${BARISTA_ROOT}/shims"
}

@test "generates zero shims when no versions are installed" {
  mkdir -p "${BARISTA_ROOT}/versions"
  run barista-restock
  assert_success
  assert_line "barista: restocked 0 shim(s) in ${BARISTA_ROOT}/shims"
}

@test "shim is executable" {
  create_version "21.0.3"
  barista-restock
  assert [ -x "${BARISTA_ROOT}/shims/java" ]
}

@test "shim contains BARISTA_ROOT reference" {
  create_version "21.0.3"
  barista-restock
  run grep "BARISTA_ROOT" "${BARISTA_ROOT}/shims/java"
  assert_success
}
