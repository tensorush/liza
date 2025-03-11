# liza

## Zig codebase initializer.

### Usage

```sh
git clone https://codeberg.org/tensorush/liza.git
cd liza/
zig build exe -- -h
```

### Features

- #### [Zig executable template](src/templates/exe/):
    - Zig executable compilation.
    - Dependency usage.
    - Binary release.

- #### [Zig library template](src/templates/lib/):
    - Zig static library compilation.
    - Public module creation.
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
    - `test`: Test suite execution and optional GitHub-only code coverage publication to [Codecov](https://docs.codecov.com/docs/github-2-getting-a-codecov-account-and-uploading-coverage#install-the-github-app-integration).
    - `fmt`: Formatting checks execution.

- #### Optional [GitHub](src/templates/.github/workflows/cd.yaml) / [Forgejo](src/templates/.forgejo/workflows/cd.yaml) / [Woodpecker](src/templates/.woodpecker/cd.yaml) CD workflow:
    - `emit`->`deploy`: documentation emission and deployment to [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow) or [Codeberg Pages](https://codeberg.page).

- #### [MIT license template](src/templates/LICENSE).

- #### [`.gitattributes`](src/templates/.gitattributes).

- #### [`.gitignore`](src/templates/.gitignore).
