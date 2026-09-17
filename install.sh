#!/usr/bin/env bash

WGET_CMD="wget -nv --show-progress --progress=bar:force"
JOBS="${JOBS:-4}"
FETCH_ONLY=0
FORCE=0

usage() {
  cat <<EOF
Usage: bash $0 [--fetch-only] [--force] <target>
       bash $0 --help

Fetch and install HPC tools in the current directory. Run from the
hpc_tools repository root; no sudo is needed. A target is required.

Options:
  -h, --help    Show this help and exit.
  --fetch-only  Download files without extracting or compiling them.
                Verify SHA-256 where a checksum is pinned in this script.
  --force       Install even if a command is on PATH or already installed here.
                Re-extract prebuilt tools and rebuild source targets.
                Cached downloads are still reused; pinned versions are unchanged.

Place options before the target, in either order. Both apply to dependencies.
With --fetch-only, --force still leaves files unextracted and unbuilt.

Prebuilt targets (Linux x86-64; no compiler needed):
  ripgrep, rg   Fast text search; installs the rg command.
  fd            File search.
  fzf           Interactive fuzzy finder.
  direnv        Per-directory environment variables.
  btop          Resource monitor.
  duf           Disk usage overview.

Source targets (require a compiler, make, and development libraries):
  htop          Process monitor; requires ncurses development files.
  tig           Git text interface; requires ncurses development files.
  openssl       OpenSSL libraries and command (alias: libssl).
  curl          curl and libcurl; builds OpenSSL first (alias: libcurl).
  git           Git; builds OpenSSL and curl first.

Groups:
  tools         All prebuilt targets listed above.
  all           tools, git (including OpenSSL and curl), tig, and htop.

Downloads use wget and are reused when already present. Existing local
installations are skipped unless forced; most prebuilt targets also skip
commands on PATH.
Source builds use JOBS parallel jobs (default: 4), e.g. JOBS=8 bash $0 git.

Tools are installed under their own subdirectories. To use them, configure
and load the supplied modulefile, or add their executable directories to PATH.
EOF
}

while (( $# )); do
  case "$1" in
    --fetch-only) FETCH_ONLY=1 ;;
    --force) FORCE=1 ;;
    -h | --help) usage; exit 0 ;;
    --) shift; break ;;
    -*) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    *) break ;;
  esac
  shift
done

verify_sha256() {
  printf '%s  %s\n' "$2" "$1" | sha256sum -c -
}

fetch_ripgrep() {
  if (( ! FETCH_ONLY && ! FORCE )) && which rg >/dev/null 2>&1; then
    echo "system ripgrep detected" && return
  fi
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -d ripgrep ]]; then
    echo "ripgrep already fetched" && return
  fi
  ripgrepver="15.1.0"
  ripgrepdir="ripgrep-$ripgrepver-x86_64-unknown-linux-musl"
  ripgreptgz="$ripgrepdir.tar.gz"
  ripgrepurl="https://github.com/BurntSushi/ripgrep/releases/download/$ripgrepver/$ripgreptgz"

  [[ -f "$ripgreptgz" ]] || $WGET_CMD "$ripgrepurl" || return
  (( FETCH_ONLY )) && return
  mkdir -p ripgrep && tar -C ripgrep --strip-components=1 -zxf "$ripgreptgz" || return
  mkdir -p ripgrep/share/man/man1 && ln -sfn ../../../doc/rg.1 ripgrep/share/man/man1/rg.1
}

fetch_fd() {
  if (( ! FETCH_ONLY && ! FORCE )) && which fd >/dev/null 2>&1; then
    echo "system fd detected" && return
  fi
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -d fd ]]; then
    echo "fd already fetched" && return
  fi
  fdver="v10.4.2"
  fddir="fd-$fdver-x86_64-unknown-linux-musl"
  fdtgz="$fddir.tar.gz"
  fdurl="https://github.com/sharkdp/fd/releases/download/$fdver/$fdtgz"

  [[ -f "$fdtgz" ]] || $WGET_CMD "$fdurl" || return
  (( FETCH_ONLY )) && return
  mkdir -p fd && tar -C fd --strip-components=1 -zxf "$fdtgz" || return
  mkdir -p fd/share/man/man1 && ln -sfn ../../../fd.1 fd/share/man/man1/fd.1
}

fetch_fzf() {
  if (( ! FETCH_ONLY && ! FORCE )) && which fzf >/dev/null 2>&1; then
    echo "system fzf detected" && return
  fi
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -d fzf ]]; then
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

fetch_btop() {
  if (( ! FETCH_ONLY && ! FORCE )) && command -v btop >/dev/null 2>&1; then
    echo "system btop detected" && return
  fi
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -x btop/bin/btop ]]; then
    echo "btop already fetched" && return
  fi

  local version="1.4.7"
  local asset="btop-x86_64-unknown-linux-musl.tar.gz"
  local tarball="btop-$version-x86_64-unknown-linux-musl.tar.gz"
  local url="https://github.com/aristocratos/btop/releases/download/v$version/$asset"
  local sha256="5099054dd6a101bd12eb6ff3702a9a6a3f57aaa27923a0da478ae5b517faf335"

  [[ -f "$tarball" ]] || $WGET_CMD -O "$tarball" "$url" || return
  verify_sha256 "$tarball" "$sha256" || return
  (( FETCH_ONLY )) && return
  tar -zxf "$tarball" || return
  mkdir -p btop/share/btop/themes &&
    cp -R btop/themes/. btop/share/btop/themes/ && rm -rf btop/themes
}

fetch_duf() {
  if (( ! FETCH_ONLY && ! FORCE )) && command -v duf >/dev/null 2>&1; then
    echo "system duf detected" && return
  fi
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -x duf/duf ]]; then
    echo "duf already fetched" && return
  fi

  local version="0.9.1"
  local tarball="duf_${version}_linux_x86_64.tar.gz"
  local url="https://github.com/muesli/duf/releases/download/v$version/$tarball"
  local sha256="5add851e7062c5e56939abb664705e4d14fa2d06289490aff31d51f153832de7"

  [[ -f "$tarball" ]] || $WGET_CMD "$url" || return
  verify_sha256 "$tarball" "$sha256" || return
  (( FETCH_ONLY )) && return
  mkdir -p duf && tar -C duf -zxf "$tarball" || return
  mkdir -p duf/share/man/man1 && ln -sfn ../../../duf.1 duf/share/man/man1/duf.1
}

fetch_direnv() {
  # if which direnv > /dev/null 2>&1; then
  #   echo "system direnv detected" && return
  # fi
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -d direnv ]]; then
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

fetch_compile_htop() {
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -x htop/bin/htop ]]; then
    echo "htop already compiled" && return
  fi

  local version="3.5.3"
  local srcdir="htop-$version"
  local tarball="$srcdir.tar.xz"
  local url="https://github.com/htop-dev/htop/releases/download/$version/$tarball"
  local sha256="a8b164386494cb85bb255a415a3f5f80afe7a0c4491da5d113b3a0f951087e65"
  local prefix="$PWD/htop"

  [[ -f "$tarball" ]] || $WGET_CMD "$url" || return
  verify_sha256 "$tarball" "$sha256" || return
  (( FETCH_ONLY )) && return
  [[ -d "$srcdir" ]] || tar -Jxf "$tarball" || return

  (
    cd "$srcdir" || exit
    ./configure --prefix="$prefix" &&
      { (( ! FORCE )) || make clean; } &&
      make -j"$JOBS" &&
      make install
  )
}

fetch_compile_tig() {
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -x tig/bin/tig ]]; then
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
      { (( ! FORCE )) || make clean; } &&
      make -j"$JOBS" &&
      make install
  )
}

# See: https://valgrind.org/docs/manual/dist.readme.html
fetch_compile_valgrind() {
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -d valgrind ]]; then
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
  if (( FORCE )) || [[ ! -d "valgrind" ]]; then
    prefix="$(pwd)/valgrind"
    cd "valgrind-$vver" || return 2
    make prefix="$prefix" && make install prefix="$prefix" && cd .. && rm -rf "valgrind-$vver"
  fi
}

fetch_compile_openssl() {
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -x openssl/bin/openssl ]]; then
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
      { (( ! FORCE )) || make clean; } &&
      make -j"$JOBS" &&
      make install_sw
  )
}

fetch_compile_curl() {
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -x curl/bin/curl ]]; then
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
      { (( ! FORCE )) || make clean; } &&
      make -j"$JOBS" &&
      make install
  )
}

fetch_compile_git() {
  if (( ! FETCH_ONLY && ! FORCE )) && [[ -x git/bin/git ]]; then
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
    csprng_method=
    if printf '%s\n' '#include <sys/random.h>' \
      'int main(void) { return getrandom(0, 0, 0) < 0; }' | \
      "${CC:-cc}" -D_GNU_SOURCE -x c -o /dev/null - >/dev/null 2>&1; then
      csprng_method=getrandom
    else
      echo "getrandom unavailable; Git will use /dev/urandom"
    fi
    make clean &&
      make -j"$JOBS" \
        prefix="$prefix" \
        OPENSSLDIR="$openssl_prefix" \
        CURLDIR="$curl_prefix" \
        CURL_CONFIG="$curl_prefix/bin/curl-config" \
        CSPRNG_METHOD="$csprng_method" \
        CC_LD_DYNPATH='-Wl,-rpath,' \
        all &&
      make \
        prefix="$prefix" \
        OPENSSLDIR="$openssl_prefix" \
        CURLDIR="$curl_prefix" \
        CURL_CONFIG="$curl_prefix/bin/curl-config" \
        CSPRNG_METHOD="$csprng_method" \
        CC_LD_DYNPATH='-Wl,-rpath,' \
        install
  )
}

install_tools() {
  fetch_ripgrep && fetch_fd && fetch_fzf && fetch_direnv && fetch_btop && fetch_duf
}

install_git_stack() {
  fetch_compile_openssl && fetch_compile_curl && fetch_compile_git
}

if (( $# != 1 )); then
  usage >&2
  exit 2
fi

case "$1" in
  tools) install_tools ;;
  ripgrep | rg) fetch_ripgrep ;;
  fd) fetch_fd ;;
  fzf) fetch_fzf ;;
  direnv) fetch_direnv ;;
  btop) fetch_btop ;;
  duf) fetch_duf ;;
  htop) fetch_compile_htop ;;
  tig) fetch_compile_tig ;;
  openssl | libssl) fetch_compile_openssl ;;
  curl | libcurl) fetch_compile_openssl && fetch_compile_curl ;;
  git) install_git_stack ;;
  all) install_tools && install_git_stack && fetch_compile_tig && fetch_compile_htop ;;
  *) echo "Unknown target: $1" >&2; usage >&2; exit 2 ;;
esac
