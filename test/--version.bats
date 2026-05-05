#!/usr/bin/env bats

load test_helper

@test "prints barista version" {
  run barista---version
  assert_success "barista 0.1.0"
}
