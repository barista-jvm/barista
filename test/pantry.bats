#!/usr/bin/env bats

load test_helper

@test "prints BARISTA_ROOT" {
  run barista-pantry
  assert_success "$BARISTA_ROOT"
}

@test "uses HOME/.barista when BARISTA_ROOT is unset" {
  BARISTA_ROOT="" run barista-pantry
  assert_success "$HOME/.barista"
}

@test "respects a custom BARISTA_ROOT" {
  BARISTA_ROOT=/custom/path run barista-pantry
  assert_success "/custom/path"
}
