# $x

## $d

### Usage

1. Add `$p` dependency to `build.zig.zon`:

```sh
zig fetch --save git+https://$g/$u/$x.git
```

2. Use `$p` dependency in `build.zig`:

```zig
const $p_dep = b.dependency("$p", .{
    .target = target,
    .optimize = optimize,
});
// Either import module
const $p_mod = $p_dep.module("$p");
<std.Build.Step.Compile>.root_module.addImport("$p", $p_mod);
// Or link artifact
const $p_art = $p_dep.artifact("$p");
<std.Build.Step.Compile>.linkLibrary($p_art);
```
