# liza

## Command-line Zig codebase initializer.

### Usage

#### Executable

- Build from source:

```sh
git clone https://codeberg.org/tensorush/liza.git
cd liza/
zig build exe -- -h
```

- Download latest release:

```sh
wget https://github.com/tensorush/liza/releases/latest/download/<archive>
tar -xf <archive> # Unix
unzip <archive> # Windows
./<binary> -h
```

#### Module

1. Add `liza` dependency to `build.zig.zon`:

```sh
zig fetch --save git+https://codeberg.org/tensorush/liza.git
```

2. Use `liza` dependency in `build.zig`:

```zig
const liza_dep = b.dependency("liza", .{
    .target = target,
    .optimize = optimize,
});
const liza_mod = liza_dep.module("liza");
<std.Build.Step.Compile>.root_module.addImport("liza", liza_mod);
```

### Features

- #### [Zig Executable Template (`exe`)](src/templates/exe/):
    - Public API module creation.
    - Dependency package usage.
    - [Build steps](src/templates/exe/build.zig):
        - `install` (default):
            - Zig executable installation.
            - All-step execution, except for `run`, `check`, and `release`.
        - `run`: Zig executable run.
        - `doc` (`$d`): Documentation emission (`--add-doc`).
        - `test`: Test suite execution.
        - `cov` (`$c`): Code coverage generation (`--add-cov`).
        - `fmt`: Formatting check execution.
        - `check` (`$s`): Compilation check for [ZLS Build-On-Save](https://zigtools.org/zls/guides/build-on-save/) (`--add-check`).
        - `release`: Release binaries' installation and archiving.

- #### [Zig Library Template (`lib`)](src/templates/lib/):
    - Public root module creation.
    - [Build steps](src/templates/lib/build.zig):
        - `install` (default):
            - Zig static library installation.
            - Example suite installation.
            - All-step execution, except for `run` and `check`.
        - `doc` (`$d`): Documentation emission (`--add-doc`).
        - `run`: Example run.
        - `test`: Test suite execution.
        - `cov` (`$c`): Code coverage generation (`--add-cov`).
        - `fmt`: Formatting check execution.
        - `check` (`$s`): Compilation check for [ZLS Build-On-Save](https://zigtools.org/zls/guides/build-on-save/) (`--add-check`).

- #### [Zig Build Template (`bld`)](src/templates/bld/):
    - Public Translate-C module creation.
    - Lazy dependency package usage.
    - Configuration option usage.
    - [Build steps](src/templates/bld/build.zig):
        - `install` (default):
            - C/C++ static library installation.
            - All-step execution.
        - `test`: Test suite execution.
        - `fmt`: Formatting check execution.

- #### [Mach Application Template (`app`)](src/templates/app/):
    - [WGSL](https://www.w3.org/TR/WGSL/) shader usage.
    - [Build steps](src/templates/app/build.zig):
        - `install` (default):
            - [Mach](https://machengine.org/) executable installation.
            - All-step execution, except for `run`.
        - `run`: [Mach](https://machengine.org/) executable run.
        - `test`: Test suite execution.
        - `fmt`: Formatting check execution.

- #### [GitHub](src/templates/.github/workflows/ci.yaml) / [Forgejo](src/templates/.forgejo/workflows/ci.yaml) / [Woodpecker](src/templates/.woodpecker/ci.yaml) CI Workflow Template:
    - `run`/`example`/`lib`/`exe` (`$s`): either `exe`'s executable run, `lib`'s example suite execution, `bld`'s library installation, or `app`'s executable installation.
    - `test`: Test suite execution and either `exe`'s or `lib`'s GitHub-only code coverage publication to [Codecov](https://docs.codecov.com/docs/github-2-getting-a-codecov-account-and-uploading-coverage#install-the-github-app-integration) (`--add-cov`).
    - `fmt`: Formatting check execution.

- #### [GitHub](src/templates/.github/workflows/cd.yaml) / [Forgejo](src/templates/.forgejo/workflows/cd.yaml) / [Woodpecker](src/templates/.woodpecker/cd.yaml) CD Workflow Template (`--add-doc`):
    - `emit`→`deploy`: either `exe`'s or `lib`'s documentation emission and deployment to [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow) or [Codeberg Pages](https://codeberg.page):
        - (Woodpecker-only) [Generate Codeberg access token](https://docs.codeberg.org/advanced/access-token/) with `repository:write` permission and add it as `TOKEN` secret available on `Push` event.
        - (Woodpecker-only) Add email as `EMAIL` secret available on `Push` event.

- #### [GitHub](src/templates/.github/workflows/release.yaml) / [Woodpecker](src/templates/.woodpecker/release.yaml) Release Workflow:
    - `release`: `exe`'s release publication using [`minisign`](https://jedisct1.github.io/minisign/):
      - Generate key pair without password: `minisign -GW`.
      - Add `./minisign.pub` as `MINISIGN_PUBLIC_KEY` secret (available on `Tag` event in Woodpecker).
      - Add `~/.minisign/minisign.key` as `MINISIGN_SECRET_KEY` secret (available on `Tag` event in Woodpecker).
      - (Woodpecker-only) [Generate Codeberg access token](https://docs.codeberg.org/advanced/access-token/) with `misc:read` and `repository:write` permissions and add it as `TOKEN` secret available to `woodpeckerci/plugin-release` on `Tag` event.

- #### [MIT License Template](src/templates/LICENSE):
    - `$y`: Current year.
    - `$n`: User name.

- #### [`.gitignore` Template](src/templates/.gitignore):
    - `$c`: Code coverage artifacts.

- #### [`.gitattributes`](src/templates/.gitattributes).
