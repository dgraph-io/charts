# Contributing

## Getting started

Development is supported on macOS and Linux. Besides `git`, the only tool you install by hand is `make`:

| System | Command |
| --- | --- |
| macOS | `xcode-select --install` |
| Debian, Ubuntu | `sudo apt-get install -y make` |
| Arch | `sudo pacman -S --needed make` |
| Fedora, Rocky, Alma | `sudo dnf install -y make` |

Then, from the repository root:

```sh
make setup
```

`make setup` installs the tools `ct lint` needs, then the pre-commit hook:

| Tool | macOS | Linux |
| --- | --- | --- |
| helm | Homebrew | pacman on Arch; Helm's install script elsewhere |
| chart-testing (`ct`) | Homebrew | release download (v3.14.0, override with `CT_VERSION`) to `~/.local/bin`; its default lint and schema files go to `~/.ct` |
| yamllint | Homebrew | the distribution's package |
| yamale | Homebrew | pipx |
| pre-commit | Homebrew | the distribution's package; pipx on Rocky and Alma |

On macOS it installs Homebrew first if it is missing. On Rocky and Alma it enables the EPEL repository, which carries yamllint and pipx. Linux installs use `sudo` unless you run as root. The Linux routes are tested on Debian, Arch, Fedora, and Rocky.

`make deps` runs the same checks and installs nothing. It stops at the first missing tool, prints the command that installs it on your system, and exits non-zero. `make -k deps` lists every missing tool.

On Linux, pipx and the chart-testing download put tools in `~/.local/bin`. If `make setup` reports that a tool is installed but not on your PATH, add that directory:

```sh
export PATH="$HOME/.local/bin:$PATH"
```

## Checks

`ct lint` checks the charts changed against `main`. The pre-commit hook runs it when a commit touches `charts/` or `ct.yaml`, and the Lint Charts workflow runs it on pull requests. Both read their settings from `ct.yaml`. `ct lint` runs `helm lint`, yamllint on each chart's `Chart.yaml` and `values.yaml`, and a schema check of `Chart.yaml`.

The hook compares against `origin/main`, so fetch it first if your clone is behind.

To run the check by hand:

```sh
make lint       # charts changed against main
make lint-all   # every chart
```

`ct.yaml` turns off two of chart-testing's checks. Version-increment checking is off because chart versions are bumped once per release, not in every pull request. Maintainer validation is off because the ratel chart lists no maintainers.

## Releasing

Chart versions are bumped in the pull request that prepares a release, not in every change. [PUBLISH.md](./PUBLISH.md) describes the release.
