#!/bin/zsh
# Copyright (c) 2026 FanXeon@Poemcoder with Codex

mi_ao_run_external() {
  local entry key
  local -a unset_arguments
  unset_arguments=()
  while IFS= read -r entry; do
    key="${entry%%=*}"
    if [[ "$key" == MI_AO_* ]]; then
      unset_arguments+=(-u "$key")
    fi
  done < <(/usr/bin/env)
  /usr/bin/env "${unset_arguments[@]}" "$@"
}
