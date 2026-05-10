#!/usr/bin/env bats

load test_helper

@test "emits PATH export for bash" {
  run barista-setup bash
  assert_success
  assert_line "export PATH=\"${BARISTA_ROOT}/shims:\${PATH}\""
}

@test "emits BARISTA_ROOT export for bash" {
  run barista-setup bash
  assert_success
  assert_line "export BARISTA_ROOT=\"${BARISTA_ROOT}\""
}

@test "defines the barista shell function for bash" {
  run barista-setup bash
  assert_success
  assert_line "barista() {"
}

@test "shell function routes session and table through sh- variants" {
  run barista-setup bash
  assert_success
  assert_line "  session | table )"
}

@test "includes rehash call by default" {
  run barista-setup bash
  assert_success
  assert_line "command barista restock 2>/dev/null || true"
}

@test "--no-rehash omits the rehash call" {
  run barista-setup --no-rehash bash
  assert_success
  refute_line "command barista restock 2>/dev/null || true"
}

@test "- flag emits only PATH setup (no shell function)" {
  run barista-setup -
  assert_success
  assert_line "export PATH=\"${BARISTA_ROOT}/shims:\${PATH}\""
  refute_line "barista() {"
}

@test "--path flag emits only PATH setup" {
  run barista-setup --path
  assert_success
  assert_line "export PATH=\"${BARISTA_ROOT}/shims:\${PATH}\""
  refute_line "barista() {"
}

@test "--no-push-path omits PATH modification" {
  run barista-setup --no-push-path bash
  assert_success
  refute_line "export PATH=\"${BARISTA_ROOT}/shims:\${PATH}\""
  assert_line "export BARISTA_ROOT=\"${BARISTA_ROOT}\""
}

@test "emits fish-compatible syntax for fish shell" {
  run barista-setup fish
  assert_success
  assert_line "set -gx PATH \"${BARISTA_ROOT}/shims\" \$PATH"
  assert_line "function barista"
}

@test "fish integration has no bash-style function syntax" {
  run barista-setup fish
  assert_success
  refute_line "barista() {"
}

@test "bash setup sources the bash completion script" {
  run barista-setup bash
  assert_success
  assert_line ". \"${BARISTA_DIR}/completions/barista.bash\""
}

@test "zsh setup adds completions directory to fpath" {
  run barista-setup zsh
  assert_success
  assert_line "fpath=(\"${BARISTA_DIR}/completions\" \$fpath)"
}

@test "fish setup adds completions directory to fish_complete_path" {
  run barista-setup fish
  assert_success
  assert_line "set -gx fish_complete_path \"${BARISTA_DIR}/completions\" \$fish_complete_path"
}

@test "zsh shell function is identical to bash shell function" {
  run barista-setup bash
  local bash_func
  bash_func="$(printf '%s\n' "${lines[@]}" | grep -A5 'barista() {')"
  run barista-setup zsh
  local zsh_func
  zsh_func="$(printf '%s\n' "${lines[@]}" | grep -A5 'barista() {')"
  assert_equal "$bash_func" "$zsh_func"
}
