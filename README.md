Tools very useful but maybe missing on HPC platform.

- [ripgrep](https://github.com/BurntSushi/ripgrep)
- [fd-find](https://github.com/sharkdp/fd)
- [fzf](https://github.com/junegunn/fzf)

## Usage

Make sure your platform can reach GitHub and
you have `git` and `wget` on it.

Clone this repository to `/path/to/hpc_tools`, run

```shell
cd ~/hpc_tools
./install.sh
```

Or run it locally and upload to `/path/to/hpc_tools` at the server.
Then copy the modulefile (`modulefile`) to somewhere handled by
environment module.
You need to edit variable `hpc_tools_home` therein to `/path/to/hpc_tools`
if the path is not `$HOME/hpc_tools`.

## [License](./LICENSE)

The MIT License (MIT).
