# $p

## Zig build of [$p]($d).

### Usage

- Add `$p` dependency to `build.zig.zon`.

```sh
zig fetch --save git+https://$g/$u/$p.git
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
