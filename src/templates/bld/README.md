# $p

[![CI][ci-shd]][ci-url]
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
// Either import module
const $p_mod = $p_dep.module("$p");
<Step.Compile>.root_module.addImport("$p", $p_mod);
// Or link artifact
const $p_art = $p_dep.artifact("$p");
<Step.Compile>.linkLibrary($p_art);
```

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/$u/$p/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/$u/$p/blob/main/.github/workflows/ci.yaml
[lc-shd]: https://img.shields.io/github/license/$u/$p.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/$u/$p/blob/main/LICENSE
