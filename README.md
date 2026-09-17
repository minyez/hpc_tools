Tools very useful but maybe missing on HPC platform.

- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd-find](https://github.com/sharkdp/fd)
- [fzf](https://github.com/junegunn/fzf)
- [direnv](https://direnv.net)
- [btop](https://github.com/aristocratos/btop)
- [duf](https://github.com/muesli/duf)
- [htop](https://htop.dev)
- [tig](https://jonas.github.io/tig)
- [valgrind](https://valgrind.org)
- [Git](https://git-scm.com) latest release, along with [OpenSSL](https://openssl-library.org) and [curl](https://curl.se) dependencies

## Usage

Make sure your platform can reach GitHub and
you have `git` and `wget` on it.

Clone this repository to `/path/to/hpc_tools`. To install the small
prebuilt tools, run

```shell
cd ~/hpc_tools
bash install.sh tools
```

Or run it locally and upload to `/path/to/hpc_tools` at the server.
Then copy the modulefile (`modulefile`) to somewhere handled by
environment module.
Remember to adapt the variable `hpc_tools_home` therein
if the path `/path/to/hpc_tools` is not `$HOME/hpc_tools`.

To download and verify the remote archives without extracting or compiling
them, place `--fetch-only` before the target. For example,

```shell
bash install.sh --fetch-only git
```

## Troubleshooting

### Tig: incompatible libtinfo or missing libtinfo.so symlink

On older CentOS systems, linking Tig may fail with:

```text
/usr/bin/ld: skipping incompatible /usr/lib/libtinfo.so when searching for -ltinfo
/usr/bin/ld: cannot find -ltinfo
```

The linker may find only 32-bit libraries while the 64-bit runtime
`/lib64/libtinfo.so.5` lacks the `libtinfo.so` symlink needed by `-ltinfo`.
Adding `-L/lib64` alone does not supply that missing filename.

Check that the runtime matches your build (ELF 64-bit x86-64):

```shell
file -L /lib64/libtinfo.so.5
```

If it matches, create a private symlink (skip if already correct) and retry
from the repository root, without sudo:

```shell
mkdir -p "$HOME/.local/lib"
ln -s /lib64/libtinfo.so.5 "$HOME/.local/lib/libtinfo.so"
LDFLAGS="-L$HOME/.local/lib ${LDFLAGS:-}" bash install.sh tig
```

For manual builds, pass the same `LDFLAGS` to `make` and `make install`.
If the runtime or ncurses headers are missing, install matching ncurses
development files locally or ask your administrator.

## [License](./LICENSE)

The MIT License (MIT).
