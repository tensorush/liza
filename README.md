# liza

## Command-line Zig codebase initializer.

### Usage

#### Executable

- Build from source

```sh
git clone https://codeberg.org/tensorush/liza.git
cd liza/
zig build exe -- -h
```

- Download latest release

```sh
wget https://github.com/tensorush/liza/releases/latest/download/<archive>
tar -xf <archive> # Linux/macOS
unzip <archive> # Windows
./<binary> -h
```

#### Module

1. Add `liza` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://codeberg.org/tensorush/liza.git
```

2. Use `liza` dependency in `build.zig`.

```zig
const liza_dep = b.dependency("liza", .{
    .target = target,
    .optimize = optimize,
});
const liza_mod = liza_dep.module("liza");
<Step.Compile>.root_module.addImport("liza", liza_mod);
```

### Features

- #### [Zig executable template](src/templates/exe/):
    - Zig executable compilation.
    - Public API module creation.
    - Dependency usage.
    - Binary release.

- #### [Zig library template](src/templates/lib/):
    - Zig static library compilation.
    - Public root module creation.
    - Example suite setup.

- #### [Zig build template](src/templates/bld/):
    - C/C++ static library compilation.
    - Configuration option usage.
    - Lazy dependency usage.

- #### [Mach application template](src/templates/app/):
    - [Mach](https://machengine.org/) application compilation.
    - [WGSL](https://www.w3.org/TR/WGSL/) shader usage.

- #### [GitHub](src/templates/.github/workflows/ci.yaml) / [Forgejo](src/templates/.forgejo/workflows/ci.yaml) / [Woodpecker](src/templates/.woodpecker/ci.yaml) CI workflow template:
    - `exe`/`example`/`lib` (`$s`): executable's run, library's example suite execution, or build's installation.
    - `test`: Test suite execution and optional (GitHub-only for now) code coverage publication to [Codecov](https://docs.codecov.com/docs/github-2-getting-a-codecov-account-and-uploading-coverage#install-the-github-app-integration).
    - `fmt`: Formatting check execution.

- #### [GitHub](src/templates/.github/workflows/cd.yaml) / [Forgejo](src/templates/.forgejo/workflows/cd.yaml) / [Woodpecker](src/templates/.woodpecker/cd.yaml) CD workflow template (optional):
    - `emit`->`deploy`: executable's or library's documentation emission and deployment to [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow) or [Codeberg Pages](https://codeberg.page).
    - (Woodpecker-only) [Generate Codeberg access token](https://docs.codeberg.org/advanced/access-token/) with `repository:write` permission and add it as `TOKEN` secret available on `Push` event.
    - (Woodpecker-only) Add email as `EMAIL` secret available on `Push` event.

- #### [GitHub](src/templates/.github/workflows/release.yaml) / [Woodpecker](src/templates/.woodpecker/release.yaml) Release workflow:
    - `release`: executable's binary release publication using [`minisign`](https://jedisct1.github.io/minisign/):
      - Generate key pair without password: `minisign -GW`.
      - Add `./minisign.pub` as `MINISIGN_PUBLIC_KEY` secret (available on `Tag` event in Woodpecker).
      - Add `~/.minisign/minisign.key` as `MINISIGN_SECRET_KEY` secret (available on `Tag` event in Woodpecker).
      - (Woodpecker-only) [Generate Codeberg access token](https://docs.codeberg.org/advanced/access-token/) with `misc:read` and `repository:write` permissions and add it as `TOKEN` secret available to `woodpeckerci/plugin-release` on `Tag` event.

- #### [MIT license template](src/templates/LICENSE).

- #### [`.gitattributes`](src/templates/.gitattributes).

- #### [`.gitignore`](src/templates/.gitignore).
