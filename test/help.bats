#!/usr/bin/env bats

load test_helper

@test "no arguments shows command list" {
  run barista-help
  assert_success
  assert_line "Usage: barista <command> [<args>]"
  assert_line "Java version management, barista-style."
}

@test "command list includes core commands" {
  run barista-help
  assert_success
  assert_line "   brew                  Install a Java version (brew a new JDK)"
  assert_line "   menu                  List all Java versions available to barista"
}

@test "command list omits internal helpers" {
  run barista-help
  assert_success
  refute_line "sh-table"
  refute_line "sh-session"
  refute_line "version-file-read"
  refute_line "version-file-write"
}

@test "help <command> prints summary and usage" {
  run barista-help brew
  assert_success
  assert_line "Summary: Install a Java version (brew a new JDK)"
  assert_line "Usage: barista brew [-f|--force] [-d|--dist <name>] <version>"
}

@test "help <command> prints flags section" {
  run barista-help brew
  assert_success
  assert_line "Flags:"
}

@test "help for unknown command fails" {
  run barista-help no-such-command
  assert_failure
  assert_output "barista: no such command 'no-such-command'"
}

@test "help serving shows version precedence" {
  run barista-help serving
  assert_success
  assert_line "Summary: Show the current Java version being served and its origin"
}
