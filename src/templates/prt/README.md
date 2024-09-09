# ?r

[![CI][ci-shd]][ci-url]
[![LC][lc-shd]][lc-url]

## ?d

### :rocket: Usage

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
// Either link artifact
const ?r_art = ?r_dep.artifact("?r");
<compile>.linkLibrary(?r_art);
// Or import module
const ?r_mod = ?r_dep.module("?r");
<compile>.root_module.addImport("?r", ?r_mod);
```

<!-- MARKDOWN LINKS -->

[ci-shd]: https://img.shields.io/github/actions/workflow/status/?u/?r/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/?u/?r/blob/main/.github/workflows/ci.yaml
[lc-shd]: https://img.shields.io/github/license/?u/?r.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/?u/?r/blob/main/LICENSE
