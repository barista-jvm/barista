#!/usr/bin/env bats

load test_helper

@test "fails when file argument is missing" {
  run barista-version-file-write
  assert_failure
}

@test "fails when version argument is missing" {
  run barista-version-file-write "${BARISTA_TEST_DIR}/version"
  assert_failure
}

@test "writes the version to the given file" {
  run barista-version-file-write "${BARISTA_TEST_DIR}/version" "21.0.3"
  assert_success
  assert_equal "21.0.3" "$(cat "${BARISTA_TEST_DIR}/version")"
}

@test "overwrites an existing file" {
  echo "17.0.9" > "${BARISTA_TEST_DIR}/version"
  run barista-version-file-write "${BARISTA_TEST_DIR}/version" "21.0.3"
  assert_success
  assert_equal "21.0.3" "$(cat "${BARISTA_TEST_DIR}/version")"
}

@test "creates the file if it does not exist" {
  local target="${BARISTA_TEST_DIR}/new-version-file"
  assert [ ! -e "$target" ]
  run barista-version-file-write "$target" "17.0.9"
  assert_success
  assert [ -e "$target" ]
  assert_equal "17.0.9" "$(cat "$target")"
}
