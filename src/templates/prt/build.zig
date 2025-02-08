const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/lib.zig");
    const version = std.SemanticVersion{?v};

    // Custom options
    const use_z = b.option(bool, "use_z", "Use system zlib") orelse false;

    // Dependencies
    const ?r_dep = b.dependency("?r", .{});
    const ?r_path = ?r_dep.path("");

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "?r",
        .target = target,
        .version = version,
        .optimize = optimize,
    });
    lib.root_module.addCMacro("VERSION", b.fmt("\"{}\"", .{version}));
    lib.addCSourceFiles(.{ .root = ?r_path, .files = &SOURCES, .flags = &FLAGS });
    lib.installHeadersDirectory(?r_path, "", .{ .include_extensions = &HEADERS });
    lib.addConfigHeader(b.addConfigHeader(.{
        .style = .{ .cmake = ?r_path.path(b, "config.h.cmake.in") },
        .include_path = "config.h",
    }, VALUES));
    lib.linkFramework("CoreFoundation");
    lib.linkLibCpp();
    lib.linkLibC();

    if (use_z) {
        lib.root_module.addCMacro("HAVE_Z", "1");
        lib.linkSystemLibrary("z");
    }

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Bindings module
    const bindings_mod = b.addModule("?r", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });
    bindings_mod.linkLibrary(lib);

    // Formatting checks
    const fmt_step = b.step("fmt", "Run formatting checks");

    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    b.default_step.dependOn(fmt_step);
}

const SOURCES = .{
    "lib.c",
};

const FLAGS = .{
    "-std=c89",
};

const HEADERS = .{
    "lib.h",
};

const VALUES = .{
    .HAVE_STD_BOOL = 1,
};
