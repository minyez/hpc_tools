#!/usr/bin/env bash

WGET_CMD="wget -nv --show-progress --progress=bar:force"

fetch_ripgrep() {
  if which rg > /dev/null 2>&1; then
    echo "system ripgrep detected" && return
  fi
  if [[ -d ripgrep ]]; then
    echo "ripgrep already fetched" && return
  fi
  ripgrepver="13.0.0"
  ripgrepdir="ripgrep-$ripgrepver-x86_64-unknown-linux-musl"
  ripgreptgz="$ripgrepdir.tar.gz"
  ripgrepurl="https://github.com/BurntSushi/ripgrep/releases/download/13.0.0/$ripgreptgz"

  [[ -f "$ripgreptgz" ]] || $WGET_CMD "$ripgrepurl"
  tar -zxf "$ripgreptgz"
  mv "$ripgrepdir" ripgrep
}

fetch_fd() {
  if which fd > /dev/null 2>&1; then
    echo "system fd detected" && return
  fi
  if [[ -d fd ]]; then
    echo "fd already fetched" && return
  fi
  fdver="v8.7.0"
  fddir="fd-$fdver-x86_64-unknown-linux-musl"
  fdtgz="$fddir.tar.gz"
  fdurl="https://github.com/sharkdp/fd/releases/download/$fdver/$fdtgz"

  [[ -f "$fdtgz" ]] || $WGET_CMD "$fdurl"
  tar -zxf "$fdtgz"
  mv "$fddir" fd
}

fetch_fzf() {
  if which fzf > /dev/null 2>&1; then
    echo "system fzf detected" && return
  fi
  if [[ -d fzf ]]; then
    echo "fzf already fetched" && return
  fi
  fzfver="0.41.1"
  fzfdir="fzf-$fzfver-linux_amd64"
  fzftgz="$fzfdir.tar.gz"
  fzfurl="https://github.com/junegunn/fzf/releases/download/$fzfver/$fzftgz"
  [[ -f "$fzftgz" ]] || $WGET_CMD "$fzfurl"
  mkdir -p fzf
  tar -C fzf -zxf "$fzftgz"
}

# fetch released binaries
fetch_ripgrep
fetch_fd
fetch_fzf

# fetch source and compile
