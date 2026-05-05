#!/usr/bin/env bats

load test_helper

@test "fails with no argument" {
  run barista-version-file-read
  assert_failure
}

@test "reads the version from a file" {
  echo "21.0.3" > "${BARISTA_TEST_DIR}/version"
  run barista-version-file-read "${BARISTA_TEST_DIR}/version"
  assert_success "21.0.3"
}

@test "reads only the first non-blank, non-comment line" {
  printf '# a comment\n\n17.0.9\n21.0.3\n' > "${BARISTA_TEST_DIR}/version"
  run barista-version-file-read "${BARISTA_TEST_DIR}/version"
  assert_success "17.0.9"
}

@test "skips comment lines" {
  printf '# comment\n21.0.3\n' > "${BARISTA_TEST_DIR}/version"
  run barista-version-file-read "${BARISTA_TEST_DIR}/version"
  assert_success "21.0.3"
}

@test "skips blank lines before the version" {
  printf '\n\n21.0.3\n' > "${BARISTA_TEST_DIR}/version"
  run barista-version-file-read "${BARISTA_TEST_DIR}/version"
  assert_success "21.0.3"
}

@test "exits silently for a nonexistent file" {
  run barista-version-file-read "${BARISTA_TEST_DIR}/no-such-file"
  assert [ "$status" -ne 0 ]
  assert_output ""
}
