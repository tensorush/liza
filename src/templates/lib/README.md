# $p

[![CI][ci-shd]][ci-url]
[![CD][cd-shd]][cd-url]
[![DC][dc-shd]][dc-url]
[![CC][cc-shd]][cc-url]
[![LC][lc-shd]][lc-url]

## $d

### Usage

- Add `$p` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/$u/$p#<git_tag_or_commit_hash>
```

- Use `$p` dependency in `build.zig`.

```zig
const $p_dep = b.dependency("$p", .{
    .target = target,
    .optimize = optimize,
});
const $p_mod = $p_dep.module("$p");
<Step.Compile>.root_module.addImport("$p", $p_mod);
```

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/$u/$p/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/$u/$p/blob/main/.github/workflows/ci.yaml
[cd-shd]: https://img.shields.io/github/actions/workflow/status/$u/$p/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/$u/$p/blob/main/.github/workflows/cd.yaml
[dc-shd]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=docs&labelColor=black
[dc-url]: https://$u.github.io/$p
[cc-shd]: https://img.shields.io/codecov/c/github/$u/$p?style=for-the-badge&labelColor=black
[cc-url]: https://app.codecov.io/gh/$u/$p
[lc-shd]: https://img.shields.io/github/license/$u/$p.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/$u/$p/blob/main/LICENSE
