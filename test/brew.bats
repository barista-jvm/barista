#!/usr/bin/env bats

load test_helper

@test "--version prints barista-brew version" {
  run barista-brew --version
  assert_success
  assert_line "barista-brew 0.1.0"
}

@test "fails with no arguments" {
  run barista-brew
  assert_failure
  assert_line "Usage: barista brew <dist>@<version>"
}

@test "fails when the version is already installed and --force is not given" {
  create_version "adoptium@21.0.3"
  run barista-brew adoptium@21.0.3
  assert_failure
  assert_line "barista: adoptium@21.0.3 is already brewed at ${BARISTA_ROOT}/versions/adoptium@21.0.3"
}

@test "--force flag is accepted for an already-installed version" {
  # We can't actually download, so just verify the flag is parsed correctly.
  # With --force the script proceeds past the "already installed" guard and
  # fails at download (no network in tests), not at the guard check.
  create_version "adoptium@21.0.3"
  run barista-brew --force adoptium@21.0.3
  # Should NOT produce the "already brewed" error
  refute_line "barista: adoptium@21.0.3 is already brewed at ${BARISTA_ROOT}/versions/adoptium@21.0.3"
}
