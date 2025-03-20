# $p

## $d

### Usage

#### Executable

```sh
git clone https://$g/$u/$p.git
cd $p/
zig build exe -- -h
```

#### Module

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
const $p_mod = $p_dep.module("$p");
<Step.Compile>.root_module.addImport("$p", $p_mod);
```
