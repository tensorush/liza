# liza

[![CI][ci-shd]][ci-url]
[![LC][lc-shd]][lc-url]

## Zig codebase initializer.

### :rocket: Usage

```sh
git clone https://github.com/tensorush/liza.git
cd liza/
zig build exe -- -h
```

### :sparkles: Features

- #### [Zig executable template](src/templates/exe/):
    - Dependency package usage.
    - Custom `build.zig.zon`.
    - README with badges.

- #### [Zig library template](src/templates/lib/):
    - Examples' directory setup.
    - Custom `build.zig.zon`.
    - README with badges.

- #### [Zig port template](src/templates/prt/):
    - C/C++/ObjC codebase compilation.
    - Custom `build.zig.zon`.
    - README with badges.

- #### [GitHub CI template](src/templates/.github/workflows/ci.yaml):
    - `exe`/`example`/`install` (`?`): executable's run, library's example suite execution, or port's installation.
    - `test`: Test suite execution and code coverage publication to [Codecov](https://docs.codecov.com/docs/github-2-getting-a-codecov-account-and-uploading-coverage#install-the-github-app-integration).
    - `fmt`: Formatting checks execution.

- #### [GitHub CD workflow](src/templates/.github/workflows/cd.yaml):
    - `emit` -> `deploy`: documentation emission and deployment to [GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site#publishing-with-a-custom-github-actions-workflow).

- #### [MIT license template](src/templates/LICENSE).

- #### [`.gitattributes`](src/templates/.gitattributes).

- #### [`.gitignore`](src/templates/.gitignore).

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/liza/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/liza/blob/main/.github/workflows/ci.yaml
[lc-shd]: https://img.shields.io/github/license/tensorush/liza.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/liza/blob/main/LICENSE
