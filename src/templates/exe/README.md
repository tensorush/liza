# $p

## $d

### Usage

#### Executable

- Build from source:

```sh
git clone https://$h/$u/$p.git
cd $p/
zig build run -- -h
```

- Download latest release:

```sh
wget https://$h/$u/$p/releases/$l/<archive>
tar -xf <archive> # Unix
unzip <archive> # Windows
./<binary> -h
```

#### Module

1. Add `$p` dependency to `build.zig.zon`:

```sh
zig fetch --save git+https://$h/$u/$p.git
```

2. Use `$p` dependency in `build.zig`:

```zig
const $p_dep = b.dependency("$p", .{
    .target = target,
    .optimize = optimize,
});
const $p_mod = $p_dep.module("$p");

const root_mod = b.createModule(.{
    .target = target,
    .optimize = optimize,
    .imports = &.{
        .{ .name = "$p", .module = $p_mod },
    },
});
```
