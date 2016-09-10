#! /usr/bin/env bats

load environment
load assertions
load script_helper
load commands/helpers

setup() {
  create_test_go_script '@go "$@"'
  find_builtins
}

teardown() {
  remove_test_go_rootdir
}

@test "$SUITE: complete help flag variations" {
  run "$TEST_GO_SCRIPT" complete 0 -h
  assert_success '-h'

  run "$TEST_GO_SCRIPT" complete 0 -he
  assert_success '-help'

  run "$TEST_GO_SCRIPT" complete 0 -
  assert_success '--help'

  run "$TEST_GO_SCRIPT" complete 0 --
  assert_success '--help'
}

@test "$SUITE: all top-level commands for zeroth or first argument" {
  # Aliases will get printed before all other commands.
  local __all_commands=("$(./go 'aliases')" "${BUILTIN_CMDS[@]}")

  run "$TEST_GO_SCRIPT" complete 0
  local IFS=$'\n'
  assert_success "${__all_commands[*]}"

  run "$TEST_GO_SCRIPT" complete 0 complete
  assert_success 'complete'

  run "$TEST_GO_SCRIPT" complete 0 complete-not
  assert_failure ''
}

@test "$SUITE: cd and pushd" {
  local subdirs=('bar' 'baz' 'foo')
  local files=('plugh' 'quux' 'xyzzy')
  mkdir -p "${subdirs[@]/#/$TEST_GO_SCRIPTS_DIR/}"
  touch "${files[@]/#/$TEST_GO_SCRIPTS_DIR/}"

  run "$TEST_GO_SCRIPT" complete 1 cd ''
  assert_success 'scripts'
  run "$TEST_GO_SCRIPT" complete 1 pushd ''
  assert_success 'scripts'

  local prev_IFS="$IFS"
  local IFS=$'\n'
  local expected=($(compgen -d "$TEST_GO_SCRIPTS_DIR/"))
  IFS="$prev_IFS"
  expected=("${expected[@]#$TEST_GO_ROOTDIR/}")

  run "$TEST_GO_SCRIPT" complete 1 cd 'scripts/'
  IFS=$'\n'
  assert_success "${expected[*]}"
  run "$TEST_GO_SCRIPT" complete 1 pushd 'scripts/'
  assert_success "${expected[*]}"
}

@test "$SUITE: edit and run" {
  local subdirs=('bar' 'baz' 'foo')
  local files=('plugh' 'quux' 'xyzzy')
  mkdir -p "${subdirs[@]/#/$TEST_GO_SCRIPTS_DIR/}"
  touch "${files[@]/#/$TEST_GO_SCRIPTS_DIR/}"

  local prevIFS="$IFS"
  local IFS=$'\n'
  local top_level=($(compgen -f "$TEST_GO_ROOTDIR/"))
  local all_scripts_entries=($(compgen -f "$TEST_GO_SCRIPTS_DIR/"))
  IFS="$prevIFS"
  top_level=("${top_level[@]#$TEST_GO_ROOTDIR/}")
  all_scripts_entries=("${all_scripts_entries[@]#$TEST_GO_ROOTDIR/}")

  run "$TEST_GO_SCRIPT" complete 1 edit ''
  local IFS=$'\n'
  assert_success "${top_level[*]}"
  run "$TEST_GO_SCRIPT" complete 1 run ''
  assert_success "${top_level[*]}"

  run "$TEST_GO_SCRIPT" complete 1 edit 'scripts/'
  assert_success "${all_scripts_entries[*]}"
  run "$TEST_GO_SCRIPT" complete 1 run 'scripts/'
  assert_success "${all_scripts_entries[*]}"
}

@test "$SUITE: unenv and unknown flag return errors" {
  run "$TEST_GO_SCRIPT" complete 1 unenv ''
  assert_failure ''

  run "$TEST_GO_SCRIPT" complete 1 --foobar ''
  assert_failure ''
}