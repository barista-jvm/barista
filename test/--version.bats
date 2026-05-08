#!/usr/bin/env bats

load test_helper

@test "prints barista version" {
  run barista---version
  assert_success "barista ${BARISTA_VERSION_STRING}"
}
