#!/usr/bin/env bash

WGET_CMD="wget -nv --show-progress --progress=bar:force"
JOBS="${JOBS:-4}"
FETCH_ONLY=0

if [[ "${1:-}" == "--fetch-only" ]]; then
  FETCH_ONLY=1
  shift
fi

verify_sha256() {
  printf '%s  %s\n' "$2" "$1" | sha256sum -c -
}

fetch_ripgrep() {
  if (( ! FETCH_ONLY )) && which rg >/dev/null 2>&1; then
    echo "system ripgrep detected" && return
  fi
  if (( ! FETCH_ONLY )) && [[ -d ripgrep ]]; then
    echo "ripgrep already fetched" && return
  fi
  ripgrepver="15.1.0"
  ripgrepdir="ripgrep-$ripgrepver-x86_64-unknown-linux-musl"
  ripgreptgz="$ripgrepdir.tar.gz"
  ripgrepurl="https://github.com/BurntSushi/ripgrep/releases/download/$ripgrepver/$ripgreptgz"

  [[ -f "$ripgreptgz" ]] || $WGET_CMD "$ripgrepurl" || return
  (( FETCH_ONLY )) && return
  tar -zxf "$ripgreptgz"
  mv "$ripgrepdir" ripgrep
}

fetch_fd() {
  if (( ! FETCH_ONLY )) && which fd >/dev/null 2>&1; then
    echo "system fd detected" && return
  fi
  if (( ! FETCH_ONLY )) && [[ -d fd ]]; then
    echo "fd already fetched" && return
  fi
  fdver="v10.4.2"
  fddir="fd-$fdver-x86_64-unknown-linux-musl"
  fdtgz="$fddir.tar.gz"
  fdurl="https://github.com/sharkdp/fd/releases/download/$fdver/$fdtgz"

  [[ -f "$fdtgz" ]] || $WGET_CMD "$fdurl" || return
  (( FETCH_ONLY )) && return
  tar -zxf "$fdtgz"
  mv "$fddir" fd
}

fetch_fzf() {
  if (( ! FETCH_ONLY )) && which fzf >/dev/null 2>&1; then
    echo "system fzf detected" && return
  fi
  if (( ! FETCH_ONLY )) && [[ -d fzf ]]; then
    echo "fzf already fetched" && return
  fi
  fzfver="0.41.1"
  fzfdir="fzf-$fzfver-linux_amd64"
  fzftgz="$fzfdir.tar.gz"
  fzfurl="https://github.com/junegunn/fzf/releases/download/$fzfver/$fzftgz"
  [[ -f "$fzftgz" ]] || $WGET_CMD "$fzfurl" || return
  (( FETCH_ONLY )) && return
  mkdir -p fzf
  tar -C fzf -zxf "$fzftgz"
}

fetch_direnv() {
  # if which direnv > /dev/null 2>&1; then
  #   echo "system direnv detected" && return
  # fi
  if (( ! FETCH_ONLY )) && [[ -d direnv ]]; then
    echo "direnv already fetched" && return
  fi
  direnvver="v2.37.1"
  direnvexe="direnv.linux-amd64"
  direnvurl="https://github.com/direnv/direnv/releases/download/$direnvver/$direnvexe"
  echo "getting $direnvurl"
  [[ -f "$direnvexe" ]] || $WGET_CMD "$direnvurl"
  if [[ ! -f "$direnvexe" ]]; then
    echo "Failed to download $direnvexe ($direnvurl)"
    return 1
  fi
  (( FETCH_ONLY )) && return
  mkdir -p direnv && mv $direnvexe direnv/direnv && chmod +x direnv/direnv
}

fetch_compile_tig() {
  if (( ! FETCH_ONLY )) && [[ -x tig/bin/tig ]]; then
    echo "tig already compiled" && return
  fi

  local version="2.5.10"
  local srcdir="tig-$version"
  local tarball="$srcdir.tar.gz"
  local url="https://github.com/jonas/tig/releases/download/tig-$version/$tarball"
  local sha256="f655cc1366fc10058a2bd505bb88ca78e653ff7526c1b81774c44b9d841210e3"
  local prefix="$PWD/tig"

  [[ -f "$tarball" ]] || $WGET_CMD "$url" || return
  verify_sha256 "$tarball" "$sha256" || return
  (( FETCH_ONLY )) && return
  [[ -d "$srcdir" ]] || tar -zxf "$tarball" || return

  (
    cd "$srcdir" || exit
    ./configure --prefix="$prefix" &&
      make -j"$JOBS" &&
      make install
  )
}

# See: https://valgrind.org/docs/manual/dist.readme.html
fetch_compile_valgrind() {
  if (( ! FETCH_ONLY )) && [[ -d valgrind ]]; then
    echo "valgrind already fetched" && return
  fi
  vver="3.24.0"
  vtarball="valgrind-$vver.tar.bz2"
  vurl="https://sourceware.org/pub/valgrind/$vtarball"
  [[ -f "$vtarball" ]] || $WGET_CMD "$vurl"
  if [[ ! -f "$vtarball" ]]; then
    echo "Failed to download $vtarball ($vurl)"
    return 1
  fi
  (( FETCH_ONLY )) && return
  [[ -d "valgrind-$vver" ]] || tar -jxf "$vtarball"
  if [[ ! -d "valgrind" ]]; then
    prefix="$(pwd)/valgrind"
    cd "valgrind-$vver" || return 2
    make prefix="$prefix" && make install prefix="$prefix" && cd .. && rm -rf "valgrind-$vver"
  fi
}

fetch_compile_openssl() {
  if (( ! FETCH_ONLY )) && [[ -x openssl/bin/openssl ]]; then
    echo "OpenSSL already compiled" && return
  fi

  local version="3.5.8"
  local srcdir="openssl-$version"
  local tarball="$srcdir.tar.gz"
  local url="https://github.com/openssl/openssl/releases/download/openssl-$version/$tarball"
  local sha256="a8f84a39918ec6415ce765d9b429d313ba97b8143169c172e734b9514464f5b2"
  local prefix="$PWD/openssl"

  [[ -f "$tarball" ]] || $WGET_CMD "$url" || return
  verify_sha256 "$tarball" "$sha256" || return
  (( FETCH_ONLY )) && return
  [[ -d "$srcdir" ]] || tar -zxf "$tarball" || return

  (
    cd "$srcdir" || exit
    unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH PKG_CONFIG_PATH
    LDFLAGS="${LDFLAGS:+$LDFLAGS }-Wl,-rpath,$prefix/lib" \
      ./config --prefix="$prefix" --openssldir="$prefix/ssl" --libdir=lib shared &&
      make -j"$JOBS" &&
      make install_sw
  )
}

fetch_compile_curl() {
  if (( ! FETCH_ONLY )) && [[ -x curl/bin/curl ]]; then
    echo "curl already compiled" && return
  fi
  if (( ! FETCH_ONLY )); then
    [[ -x openssl/bin/openssl ]] || {
      echo "OpenSSL must be installed first" >&2
      return 1
    }
  fi

  local version="8.21.0"
  local srcdir="curl-$version"
  local tarball="$srcdir.tar.gz"
  local url="https://curl.se/download/$tarball"
  local sha256="d9b327997999045a24cda50f3983e69e51c516bd8be6ef9842fc7f99135e33bb"
  local prefix="$PWD/curl"
  local openssl_prefix="$PWD/openssl"

  [[ -f "$tarball" ]] || $WGET_CMD "$url" || return
  verify_sha256 "$tarball" "$sha256" || return
  (( FETCH_ONLY )) && return
  [[ -d "$srcdir" ]] || tar -zxf "$tarball" || return

  (
    cd "$srcdir" || exit
    unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH
    export CPPFLAGS="-I$openssl_prefix/include"
    export LDFLAGS="-L$openssl_prefix/lib -Wl,-rpath,$openssl_prefix/lib -Wl,-rpath,$prefix/lib"
    export PKG_CONFIG_PATH="$openssl_prefix/lib/pkgconfig"
    ./configure \
      --prefix="$prefix" \
      --disable-static \
      --with-openssl="$openssl_prefix" \
      --with-ca-bundle=/etc/pki/tls/certs/ca-bundle.crt \
      --without-libpsl &&
      make -j"$JOBS" &&
      make install
  )
}

fetch_compile_git() {
  if (( ! FETCH_ONLY )) && [[ -x git/bin/git ]]; then
    echo "Git already compiled" && return
  fi
  if (( ! FETCH_ONLY )); then
    [[ -x openssl/bin/openssl && -x curl/bin/curl ]] || {
      echo "OpenSSL and curl must be installed first" >&2
      return 1
    }
  fi

  local version="2.54.0"
  local srcdir="git-$version"
  local tarball="$srcdir.tar.gz"
  local url="https://github.com/git/git/archive/refs/tags/v$version.tar.gz"
  local sha256="7b01a23c44c9ccfca2e3ad9daf8cbdd4d4caaaa6b5181e77e16e60c6ae5f772a"
  local prefix="$PWD/git"
  local openssl_prefix="$PWD/openssl"
  local curl_prefix="$PWD/curl"

  [[ -f "$tarball" ]] || $WGET_CMD -O "$tarball" "$url" || return
  verify_sha256 "$tarball" "$sha256" || return
  (( FETCH_ONLY )) && return
  [[ -d "$srcdir" ]] || tar -zxf "$tarball" || return

  (
    cd "$srcdir" || exit
    unset CPATH C_INCLUDE_PATH CPLUS_INCLUDE_PATH LIBRARY_PATH PKG_CONFIG_PATH
    export PATH="$openssl_prefix/bin:$curl_prefix/bin:$PATH"
    make clean &&
      make -j"$JOBS" \
        prefix="$prefix" \
        OPENSSLDIR="$openssl_prefix" \
        CURLDIR="$curl_prefix" \
        CURL_CONFIG="$curl_prefix/bin/curl-config" \
        CC_LD_DYNPATH='-Wl,-rpath,' \
        all &&
      make \
        prefix="$prefix" \
        OPENSSLDIR="$openssl_prefix" \
        CURLDIR="$curl_prefix" \
        CURL_CONFIG="$curl_prefix/bin/curl-config" \
        CC_LD_DYNPATH='-Wl,-rpath,' \
        install
  )
}

install_tools() {
  fetch_ripgrep && fetch_fd && fetch_fzf && fetch_direnv
}

install_git_stack() {
  fetch_compile_openssl && fetch_compile_curl && fetch_compile_git
}

case "${1:-tools}" in
  tools) install_tools ;;
  tig) fetch_compile_tig ;;
  openssl | libssl) fetch_compile_openssl ;;
  curl | libcurl) fetch_compile_openssl && fetch_compile_curl ;;
  git) install_git_stack ;;
  all) install_tools && install_git_stack && fetch_compile_tig ;;
  *) echo "Usage: $0 [--fetch-only] [tools|tig|openssl|curl|git|all]" >&2; exit 2 ;;
esac
