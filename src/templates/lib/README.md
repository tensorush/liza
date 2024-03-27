# :lizard: :zap: ?t

[![CI][ci-shd]][ci-url]
[![CD][cd-shd]][cd-url]
[![DC][dc-shd]][dc-url]
[![CC][cc-shd]][cc-url]
[![LC][lc-shd]][lc-url]

## ?d

### :rocket: Usage

1. Add `?t` as a dependency in your `build.zig.zon`.

    <details>

    <summary><code>build.zig.zon</code> example</summary>

    ```zig
    .dependencies = .{
        .?t = .{
            .url = "https://github.com/?h/?t/archive/<git_tag_or_commit_hash>.tar.gz",
            .hash = "<package_hash>",
        },
    },
    ```

    Set `<package_hash>` to `12200000000000000000000000000000000000000000000000000000000000000000` and build your package to find the correct value specified in a compiler error message.

    </details>

2. Add `?t` as a module in your `build.zig`.

    <details>

    <summary><code>build.zig</code> example</summary>

    ```zig
    const ?t_dep = b.dependency("?t", .{});
    const ?t_mod = ?t.module("?t");
    exe.root_module.addImport("?t", ?t_mod);
    ```

    </details>

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/?h/?t/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/?h/?t/blob/main/.github/workflows/ci.yaml
[cd-shd]: https://img.shields.io/github/actions/workflow/status/?h/?t/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/?h/?t/blob/main/.github/workflows/cd.yaml
[dc-shd]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=doc&labelColor=black
[dc-url]: https://?h.github.io/?t
[cc-shd]: https://img.shields.io/codecov/c/github/?h/?t?style=for-the-badge&labelColor=black
[cc-url]: https://app.codecov.io/gh/?h/?t
[lc-shd]: https://img.shields.io/github/license/?h/?t.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/?h/?t/blob/main/LICENSE.md
