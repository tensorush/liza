# ?r

[![CI][ci-shd]][ci-url]
[![CD][cd-shd]][cd-url]
[![DC][dc-shd]][dc-url]
[![CC][cc-shd]][cc-url]
[![LC][lc-shd]][lc-url]

## ?d

### Usage

- Add `?r` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/?u/?r#<git_tag_or_commit_hash>
```

- Use `?r` dependency in `build.zig`.

```zig
const ?r_dep = b.dependency("?r", .{
    .target = target,
    .optimize = optimize,
});
const ?r_mod = ?r_dep.module("?r");
<compile>.root_module.addImport("?r", ?r_mod);
```

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/?u/?r/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/?u/?r/blob/main/.github/workflows/ci.yaml
[cd-shd]: https://img.shields.io/github/actions/workflow/status/?u/?r/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/?u/?r/blob/main/.github/workflows/cd.yaml
[dc-shd]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=doc&labelColor=black
[dc-url]: https://?u.github.io/?r
[cc-shd]: https://img.shields.io/codecov/c/github/?u/?r?style=for-the-badge&labelColor=black
[cc-url]: https://app.codecov.io/gh/?u/?r
[lc-shd]: https://img.shields.io/github/license/?u/?r.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/?u/?r/blob/main/LICENSE
