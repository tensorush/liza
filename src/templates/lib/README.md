# $p

## $d

### Usage

- Add `$p` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://github.com/$u/$p
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
