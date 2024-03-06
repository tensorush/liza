# :lizard: :star: liza

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

- #### [Continuous integration GitHub workflow](src/templates/.github/workflows/ci.yaml):
    - `?` (`exe` or `examples`): executable's run or library's example suite execution.
    - `tests`: Test suite execution and code coverage publication to Codecov.
    - `lints`: Linting checks.

- #### [Continuous delivery GitHub workflow](src/templates/.github/workflows/cd.yaml):
    - Docs emission and deployment to GitHub Pages.

- #### [Zig executable template](src/templates/exe/):
    - Dependency package usage.
    - Custom GitHub README.
    - `build.zig.zon`.

- #### [Zig library template](src/templates/lib/):
    - Examples' directory setup.
    - Custom GitHub README.
    - `build.zig.zon`.

- #### [MIT license template](src/templates/LICENSE.md).

- #### [`.gitattributes`](src/templates/.gitattributes).

- #### [`.gitignore`](src/templates/.gitignore).

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/tensorush/liza/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/liza/blob/main/.github/workflows/ci.yaml
[lc-shd]: https://img.shields.io/github/license/tensorush/liza.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/liza/blob/main/LICENSE.md
