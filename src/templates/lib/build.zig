const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = std.Build.LazyPath.relative("src/lib.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

    // Module
    const lib_mod = b.addModule("?", .{ .root_source_file = root_source_file });

    // Library
    const lib_step = b.step("lib", "Install library");

    const lib = b.addStaticLibrary(.{
        .name = "?",
        .target = target,
        .version = version,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    b.default_step.dependOn(lib_step);

    // Docs
    const docs_step = b.step("docs", "Emit docs");

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    b.default_step.dependOn(docs_step);

    // Examples
    const examples_step = b.step("examples", "Run examples");

    inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
        const example = b.addExecutable(.{
            .name = EXAMPLE_NAME,
            .target = target,
            .version = version,
            .optimize = optimize,
            .root_source_file = std.Build.LazyPath.relative(EXAMPLES_DIR ++ EXAMPLE_NAME ++ "/main.zig"),
        });
        example.root_module.addImport("?", lib_mod);

        const example_run = b.addRunArtifact(example);
        examples_step.dependOn(&example_run.step);
    }

    b.default_step.dependOn(examples_step);

    // Tests
    const tests_step = b.step("tests", "Run tests");

    const tests = b.addTest(.{
        .target = target,
        .root_source_file = root_source_file,
    });

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
    b.default_step.dependOn(tests_step);

    // Coverage
    const cov_step = b.step("cov", "Generate coverage");

    const cov_run = b.addSystemCommand(&.{ "kcov", "--clean", "--include-pattern=src/", "kcov-output" });
    cov_run.addArtifactArg(tests);
    cov_step.dependOn(&cov_run.step);
    b.default_step.dependOn(cov_step);

    // Lints
    const lints_step = b.step("lints", "Run lints");

    const lints = b.addFmt(.{
        .paths = &.{ "src/", "build.zig" },
        .check = true,
    });
    lints_step.dependOn(&lints.step);
    b.default_step.dependOn(lints_step);
}

const EXAMPLES_DIR = "examples/";

const EXAMPLE_NAMES = &.{
    "example1",
    "example2",
};
