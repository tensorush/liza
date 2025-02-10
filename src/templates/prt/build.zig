const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/root.zig");
    const version = std.SemanticVersion{?v};

    // Custom options
    const use_zlib = b.option(bool, "use_zlib", "Use zlib built with Zig") orelse false;

    // Dependencies
    const ?r_dep = b.dependency("?r", .{
        .target = target,
        .optimize = optimize,
    });
    const ?r_path = ?r_dep.path("");
    const ?r_src_path = ?r_dep.path("src/");
    const ?r_test_path = ?r_dep.path("test/");
    const ?r_include_path = ?r_dep.path("include/");

    const zlib_dep = if (use_zlib) b.lazyDependency("zlib", .{
        .target = target,
        .optimize = optimize,
    }) else null;
    const zlib_art = if (use_zlib) zlib_dep.?.artifact("z") else undefined;

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addLibrary(.{
        .name = "?r",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .link_libc = true,
            // .link_libcpp = true,
            .optimize = optimize,
        }),
    });
    lib.addCSourceFiles(.{ .root = ?r_src_path, .files = &SOURCES, .flags = &FLAGS });
    lib.installHeadersDirectory(?r_include_path, "", .{ .include_extensions = &HEADERS });
    lib.addConfigHeader(b.addConfigHeader(.{
        .style = .{ .cmake = ?r_path.path(b, "config.h.cmake.in") },
        .include_path = "config.h",
    }, CONFIG_VALUES));
    if (use_zlib) {
        lib.root_module.addCMacro("HAVE_Z", "1");
        lib.linkLibrary(zlib_art);
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

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addExecutable(.{
        .name = "test",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
        }),
    });
    tests.addCSourceFiles(.{ .root = ?r_test_path, .files = &TEST_SOURCES, .flags = &TEST_FLAGS });

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
    b.default_step.dependOn(tests_step);

    // Code coverage
    const cov_step = b.step("cov", "Generate code coverage");

    const cov_run = b.addSystemCommand(&.{ "kcov", "--clean", "--include-pattern=src/", "kcov-output/" });
    cov_run.addArtifactArg(tests);
    cov_step.dependOn(&cov_run.step);
    b.default_step.dependOn(cov_step);

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

const CONFIG_VALUES = .{
    .HAVE_STD_BOOL = 1,
};

const TEST_SOURCES = .{
    "test.c",
};

const TEST_FLAGS = .{
    "-g3",
};
