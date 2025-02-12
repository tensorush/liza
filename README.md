# liza

[![CI][ci-shd]][ci-url]
[![LC][lc-shd]][lc-url]

## Zig codebase initializer.

### Usage

```sh
git clone https://github.com/tensorush/liza.git
cd liza/
zig build exe -- -h
```

### Features

- #### [Zig executable template](src/templates/exe/):
    - Zig executable compilation.
    - Dependency usage.

- #### [Zig library template](src/templates/lib/):
    - Zig static library compilation.
    - Example suite setup.

- #### [Zig port template](src/templates/prt/):
    - C/C++ library compilation.
    - Lazy dependency usage.

- #### [GitHub](src/templates/.github/workflows/ci.yaml) or [Forgejo](src/templates/.forgejo/workflows/ci.yaml) CI workflow template:
    - `exe`/`example`/`lib` (`?`): executable's run, library's example suite execution, or port's installation.
    - `test`: Test suite execution and code coverage publication to [Codecov](https://docs.codecov.com/docs/github-2-getting-a-codecov-account-and-uploading-coverage#install-the-github-app-integration) (only GitHub for now).
    - `fmt`: Formatting checks execution.

- #### [GitHub](src/templates/.github/workflows/cd.yaml) or [Forgejo](src/templates/.forgejo/workflows/cd.yaml) CD workflow:
    - `emit`->`deploy`: documentation emission and deployment to [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow) or [Codeberg Pages](https://codeberg.page).

- #### [MIT license template](src/templates/LICENSE).

- #### [`.gitattributes`](src/templates/.gitattributes).

- #### [`.gitignore`](src/templates/.gitignore).

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/liza/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/liza/blob/main/.github/workflows/ci.yaml
[lc-shd]: https://img.shields.io/github/license/tensorush/liza.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/liza/blob/main/LICENSE
