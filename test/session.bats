#!/usr/bin/env bats

load test_helper

@test "fails when BARISTA_VERSION is not set" {
  run barista-session
  assert_failure
  assert_output "barista: BARISTA_VERSION is not set"
}

@test "shows current BARISTA_VERSION when set" {
  BARISTA_VERSION=21.0.3 run barista-session
  assert_success "21.0.3"
}

@test "emits export statement for bash/zsh" {
  create_version "21.0.3"
  run barista-session 21.0.3
  assert_success
  assert_output 'export BARISTA_VERSION="21.0.3"'
}

@test "emits set -gx statement for fish" {
  create_version "21.0.3"
  BARISTA_SHELL=fish run barista-session 21.0.3
  assert_success 'set -gx BARISTA_VERSION "21.0.3"'
}

@test "--unset emits unset for bash/zsh" {
  run barista-session --unset
  assert_success "unset BARISTA_VERSION"
}

@test "--unset emits set -e for fish" {
  BARISTA_SHELL=fish run barista-session --unset
  assert_success "set -e BARISTA_VERSION"
}

@test "- (dash) also unsets" {
  run barista-session -
  assert_success "unset BARISTA_VERSION"
}

@test "fails when the requested version is not installed" {
  run barista-session 99.0.0
  assert_failure
  assert_line "barista: version '99.0.0' not installed"
}

@test "allows setting system" {
  run barista-session system
  assert_success 'export BARISTA_VERSION="system"'
}
