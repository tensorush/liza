# $p

## $d

### Usage

#### Executable

- Build from source:

```sh
git clone https://$g/$u/$p.git
cd $p/
zig build run -- -h
```

- Download latest release:

```sh
wget https://$g/$u/$p/releases/$l/<archive>
tar -xf <archive> # Unix
unzip <archive> # Windows
./<binary> -h
```

#### Module

1. Add `$p` dependency to `build.zig.zon`:

```sh
zig fetch --save git+https://$g/$u/$p.git
```

2. Use `$p` dependency in `build.zig`:

```zig
const $p_dep = b.dependency("$p", .{
    .target = target,
    .optimize = optimize,
});
const $p_mod = $p_dep.module("$p");
<std.Build.Step.Compile>.root_module.addImport("$p", $p_mod);
```
