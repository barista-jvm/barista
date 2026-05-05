#!/usr/bin/env bats

load test_helper

@test "lists core commands" {
  run barista-commands
  assert_success
  assert_line "brew"
  assert_line "discard"
  assert_line "menu"
  assert_line "serving"
  assert_line "house"
  assert_line "table"
  assert_line "session"
  assert_line "pour"
  assert_line "restock"
  assert_line "setup"
  assert_line "origin"
  assert_line "counter"
  assert_line "pantry"
  assert_line "commands"
  assert_line "help"
  assert_line "--version"
}

@test "omits shell-function helpers by default" {
  run barista-commands
  assert_success
  refute_line "sh-table"
  refute_line "sh-session"
}

@test "--sh includes shell-function helpers" {
  run barista-commands --sh
  assert_success
  assert_line "sh-table"
  assert_line "sh-session"
}

@test "output is sorted" {
  run barista-commands
  assert_success
  local sorted
  sorted="$(echo "$output" | sort)"
  assert_equal "$sorted" "$output"
}
