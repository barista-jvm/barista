#!/usr/bin/env bats

load test_helper

_setup() {
  mkdir -p "${BARISTA_TEST_DIR}/myproject"
  cd "${BARISTA_TEST_DIR}/myproject"
}

@test "fails when no local version is set" {
  run barista-table
  assert_failure
  assert_output "barista: no local version set"
}

@test "reads the local .java-version file" {
  echo "21.0.3" > .java-version
  run barista-table
  assert_success "21.0.3"
}

@test "discovers version file in a parent directory" {
  create_version "17.0.9"
  echo "17.0.9" > .java-version
  mkdir -p subdir
  cd subdir
  run barista-table
  assert_success "17.0.9 (set by ${BARISTA_TEST_DIR}/myproject/.java-version)"
}

@test "sets the local version" {
  create_version "21.0.3"
  run barista-table 21.0.3
  assert_success
  assert [ "$(cat .java-version)" = "21.0.3" ]
}

@test "local version file contains the written version" {
  create_version "17.0.9"
  barista-table 17.0.9
  assert_equal "17.0.9" "$(cat .java-version)"
}

@test "fails to set a version that is not installed" {
  run barista-table 99.0.0
  assert_failure
  assert_line "barista: version '99.0.0' not installed"
  assert [ ! -e .java-version ]
}

@test "sets a nonexistent version with --force" {
  run barista-table --force 99.0.0
  assert_success
  assert [ "$(cat .java-version)" = "99.0.0" ]
}

@test "-f is an alias for --force" {
  run barista-table -f 99.0.0
  assert_success
  assert [ "$(cat .java-version)" = "99.0.0" ]
}

@test "changes an existing local version" {
  create_version "17.0.9"
  create_version "21.0.3"
  echo "17.0.9" > .java-version
  run barista-table 21.0.3
  assert_success
  assert_equal "21.0.3" "$(cat .java-version)"
}

@test "--unset removes the local .java-version file" {
  touch .java-version
  run barista-table --unset
  assert_success
  assert [ ! -e .java-version ]
}

@test "--unset fails when there is no local version file" {
  run barista-table --unset
  assert_failure
  assert_output "barista: no local version file in current directory"
}
