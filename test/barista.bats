#!/usr/bin/env bats

load test_helper

@test "no arguments prints help" {
  run barista
  assert_success
  assert_line "Usage: barista <command> [<args>]"
}

@test "-h flag prints help" {
  run barista -h
  assert_success
  assert_line "Usage: barista <command> [<args>]"
}

@test "--help flag prints help" {
  run barista --help
  assert_success
  assert_line "Usage: barista <command> [<args>]"
}

@test "--version flag delegates to barista---version" {
  run barista --version
  assert_success "barista ${BARISTA_VERSION_STRING}"
}

@test "-v flag delegates to barista---version" {
  run barista -v
  assert_success "barista ${BARISTA_VERSION_STRING}"
}

@test "unknown command fails with an error message" {
  run barista no-such-command
  assert_failure
  assert_output "barista: no such command 'no-such-command'"
}

@test "dispatches a known subcommand" {
  run barista pantry
  assert_success "$BARISTA_ROOT"
}

@test "passes arguments through to the subcommand" {
  run barista serving --bare
  assert_success "system"
}
