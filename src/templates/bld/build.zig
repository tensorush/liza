const std = @import("std");

const MANIFEST = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const version: std.SemanticVersion = try .parse(MANIFEST.version);

    // Configuration options
    const use_zlib = b.option(bool, "use_zlib", "Use zlib built with Zig") orelse false;

    // Dependencies
    const $p_dep = b.dependency("$p", .{
        .target = target,
        .optimize = optimize,
    });
    const $p_path = $p_dep.path("");
    const $p_src_path = $p_dep.path("src/");
    const $p_test_path = $p_dep.path("test/");
    const $p_include_path = $p_dep.path("include/");

    const zlib_dep_lazy = if (use_zlib) b.lazyDependency("zlib", .{
        .target = target,
        .optimize = optimize,
    }) else null;
    const zlib_art = if (zlib_dep_lazy) |zlib_dep| zlib_dep.artifact("z") else undefined;

    // Translate-C module
    const c = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = $p_include_path.path(b, "$p.h"),
    });
    _ = c.addModule("$p");

    // Library
    const lib = b.addLibrary(.{
        .name = "$p",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .link_libc = true,
            // .link_libcpp = true,
            .optimize = optimize,
        }),
    });
    lib.addCSourceFiles(.{ .root = $p_src_path, .files = &SOURCES, .flags = &FLAGS });
    lib.installHeadersDirectory($p_include_path, "", .{ .include_extensions = &HEADERS });
    lib.addConfigHeader(b.addConfigHeader(.{
        .style = .{ .cmake = $p_path.path(b, "config.h.cmake.in") },
        .include_path = "config.h",
    }, CONFIG_VALUES));
    if (use_zlib) {
        lib.root_module.addCMacro("HAVE_Z", "1");
        lib.linkLibrary(zlib_art);
    }
    b.installArtifact(lib);

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addExecutable(.{
        .name = "test",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .link_libc = true,
            // .link_libcpp = true,
            .root_source_file = $p_test_path.path(b, "main.c"),
        }),
    });
    tests.addCSourceFiles(.{ .root = $p_test_path, .files = &TEST_SOURCES, .flags = &TEST_FLAGS });

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
    install_step.dependOn(tests_step);

    // Formatting check
    const fmt_step = b.step("fmt", "Check formatting");

    const fmt = b.addFmt(.{
        .paths = &.{
            "build.zig",
            "build.zig.zon",
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    install_step.dependOn(fmt_step);
}

const SOURCES = .{
    "$p.c",
};

const FLAGS = .{
    "-std=c89",
};

const HEADERS = .{
    "$p.h",
};

const CONFIG_VALUES = .{
    .HAVE_STD_BOOL = 1,
};

const TEST_SOURCES = .{
    "test.c",
};

const TEST_FLAGS = .{
    "-g3",
};
