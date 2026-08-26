Tools very useful but maybe missing on HPC platform.

- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd-find](https://github.com/sharkdp/fd)
- [fzf](https://github.com/junegunn/fzf)
- [direnv](https://direnv.net)
- [tig](https://jonas.github.io/tig)
- [valgrind](https://valgrind.org)
- [OpenSSL](https://openssl-library.org)
- [curl](https://curl.se)
- [Git](https://git-scm.com)

## Usage

Make sure your platform can reach GitHub and
you have `git` and `wget` on it.

Clone this repository to `/path/to/hpc_tools`. To install the small
prebuilt tools, run

```shell
cd ~/hpc_tools
bash install.sh
```

Or run it locally and upload to `/path/to/hpc_tools` at the server.
Then copy the modulefile (`modulefile`) to somewhere handled by
environment module.
Remember to adapt the variable `hpc_tools_home` therein
if the path `/path/to/hpc_tools` is not `$HOME/hpc_tools`.

To build a self-contained Git stack without relying on the HPC nodes'
OpenSSL or libcurl, use a modern compiler and run

```shell
module load compiler/devtoolset/11.2.1
JOBS=4 bash install.sh git
export PATH="$PWD/git/bin:$PWD/curl/bin:$PWD/openssl/bin:$PATH"
```

This builds OpenSSL 3.5.8 LTS, curl 8.21.0, and Git 2.54.0 in that order.
`tig`, `openssl`, `curl`, `libssl`, and `libcurl` are also accepted as
individual targets. Dependencies in the Git stack are built automatically;
building Tig requires the ncurses development headers.

To download and verify the remote archives without extracting or compiling
them, place `--fetch-only` before the target. For example,

```shell
bash install.sh --fetch-only git
```

## TODO

- [ ] htop
- [x] modern git

## [License](./LICENSE)

The MIT License (MIT).
