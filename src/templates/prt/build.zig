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
    lib.addCSourceFiles(.{ .root = ?r_path, .files = &SOURCES, .flags = &FLAGS });
    lib.installHeadersDirectory(?r_path, "", .{ .include_extensions = &HEADERS });
    lib.addConfigHeader(b.addConfigHeader(.{
        .style = .{ .autoconf = b.path("config/config.h.in") },
        .include_path = "config/config.h",
    }, VALUES));
    if (use_z) {
        lib.linkSystemLibrary("z");
    }
    // lib.linkFramework("CoreFoundation");
    // lib.linkLibCpp();
    // lib.linkLibC();

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Bindings
    const bindings_mod = b.addModule("?r", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });
    bindings_mod.linkLibrary(lib);

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .target = target,
        .version = version,
        .root_source_file = root_source_file,
    });

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
            "build.zig",
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    b.default_step.dependOn(fmt_step);
}

const SOURCES = .{
    // "lib.c",
};

const FLAGS = .{
    // "-std=c89",
};

const HEADERS = .{
    // "lib.h",
};

const VALUES = .{
    // .HAVE_STD_BOOL = 1,
};
