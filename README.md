# liza

## Zig codebase initializer.

### Usage

#### Executable

- Build from source:

```sh
git clone https://codeberg.org/tensorush/liza.git
cd liza/
zig build run -- -h
```

- Download latest release:

```sh
wget https://github.com/tensorush/liza/releases/latest/download/<archive>
tar -xf <archive> # Unix
unzip <archive> # Windows
./<binary> -h
```

### Features

- #### [Zig Executable Template (`exe`)](src/templates/exe/):
    - Public API module creation.
    - Dependency package usage.
    - Common build options exposure (see below).
    - [Build steps](src/templates/exe/build.zig):
        - `install` (default):
            - Zig executable installation.
            - Common build steps execution (see below).
        - `run`: Zig executable run.
        - `release`: Release binaries' installation and archiving.
        - Optional build steps (see below).

- #### [Zig Library Template (`lib`)](src/templates/lib/):
    - Public root module creation.
    - Common build options exposure (see below).
    - [Build steps](src/templates/lib/build.zig):
        - `install` (default):
            - Zig static library installation.
            - Common build steps execution (see below).
        - `run`: Example suite execution.
        - Optional build steps (see below).

- #### [Zig Build Template (`bld`)](src/templates/bld/):
    - Public Translate-C module creation.
    - Lazy dependency package usage.
    - Configuration option usage.
    - [Build steps](src/templates/bld/build.zig):
        - `install` (default):
            - C/C++ static library installation.
            - Common build steps execution (see below).

- #### Common Build Steps:
    - `test`: Test suite execution.
    - `fmt`: Formatting check execution.

- #### Custom Build Steps:
    - `tag` (`$t`): Next version tag with [Zq](https://codeberg.org/tensorush/zq).
    - `update` (`$u`): Dependencies and minimum Zig version update with [Zq](https://codeberg.org/tensorush/zq).

- #### Optional Build Steps:
    - `doc` (`$d`): Documentation emission (`-d`, `doc`).
    - `cov` (`$c`): [Kcov source code coverage](https://github.com/SimonKagstrom/kcov) generation (`-c`, `cov`).
    - `lint` (`$l`): [Vale markup prose linting check](https://github.com/errata-ai/vale) execution (`-l`, `lint`).
    - `spell` (`$s`): [Typos source code spelling check](https://github.com/crate-ci/typos) execution (`-s`, `spell`).
    - `check` (`$k`): Build compilation check for [ZLS Build-On-Save](https://zigtools.org/zls/guides/build-on-save/) (`-k`, `check`).

- #### Common Build Options:
    - `-Ddebug`: Test suite execution under [LLDB debugger](https://lldb.llvm.org/).
    - `-Dstrip`: Compilation without stack trace printing code.
    - `-Dprofile`: Compilation with [Tracy profiler Zig bindings](https://github.com/Games-by-Mason/tracy_zig) support.
    - `-Dno-bin -fincremental --watch`: Incremental compilation without binary emission.

- #### [GitHub](src/templates/.github/workflows/ci.yaml) / [Forgejo](src/templates/.forgejo/workflows/ci.yaml) / [Woodpecker](src/templates/.woodpecker/ci.yaml) CI Workflow Template Jobs:
    - `install`:
        - Main artifacts' installation.
        - `test`: Test suite execution.
        - `fmt`: Formatting check execution.
        - (**GitHub-only**) `cov` (`$c`): [Kcov source code coverage](https://github.com/SimonKagstrom/kcov) publication to [Codecov](https://docs.codecov.com/docs/github-2-getting-a-codecov-account-and-uploading-coverage#install-the-github-app-integration) (`-c`, `cov`).

- #### [GitHub](src/templates/.github/workflows/cd.yaml) / [Forgejo](src/templates/.forgejo/workflows/cd.yaml) / [Woodpecker](src/templates/.woodpecker/cd.yaml) CD Workflow Template Jobs:
    - (**`exe`-/`lib`-only**) `emit`→`deploy`: Documentation emission and deployment to [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow) or [Codeberg Pages](https://codeberg.page) (`-d`, `doc`):
        - (**Woodpecker-only**) [Generate Codeberg access token](https://docs.codeberg.org/advanced/access-token/) with `repository:write` permission and add it as `TOKEN` secret available on `Push` event.
        - (**Woodpecker-only**) Add email as `EMAIL` secret available on `Push` event.

- #### [GitHub](src/templates/.github/workflows/release.yaml) / [Woodpecker](src/templates/.woodpecker/release.yaml) Release Workflow Jobs:
    - (**`exe`-only**) `release`: Release publication using [minisign](https://jedisct1.github.io/minisign/):
      - Generate key pair without password: `minisign -GW`.
      - Add `./minisign.pub` as `MINISIGN_PUBLIC_KEY` secret (available on `Tag` event in Woodpecker).
      - Add `~/.minisign/minisign.key` as `MINISIGN_SECRET_KEY` secret (available on `Tag` event in Woodpecker).
      - (**Woodpecker-only**) [Generate Codeberg access token](https://docs.codeberg.org/advanced/access-token/) with `misc:read` and `repository:write` permissions and add it as `TOKEN` secret available to `woodpeckerci/plugin-release` on `Tag` event.

- #### [MIT License Template](src/templates/LICENSE):
    - `$y`: Current year.
    - `$n`: User name.

- #### [`.gitignore` Template](src/templates/.gitignore):
    - `$c`: [Kcov source code coverage](https://github.com/SimonKagstrom/kcov) artifacts (`-c`, `cov`).

- #### [`.gitattributes`](src/templates/.gitattributes).
