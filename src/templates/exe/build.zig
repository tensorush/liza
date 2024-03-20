const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = std.Build.LazyPath.relative("src/main.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 1, .patch = 0 };

    // Dependencies
    const clap_dep = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });
    const clap_mod = clap_dep.module("clap");

    // Executable
    const exe_step = b.step("exe", "Run executable");

    const exe = b.addExecutable(.{
        .name = "?",
        .target = target,
        .version = version,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });
    exe.root_module.addImport("clap", clap_mod);
    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_run.addArgs(args);
    }
    exe_step.dependOn(&exe_run.step);
    b.default_step.dependOn(exe_step);

    // Docs
    const docs_step = b.step("docs", "Emit docs");

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = exe.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    b.default_step.dependOn(docs_step);

    // Tests
    const tests_step = b.step("tests", "Run tests");

    const tests = b.addTest(.{
        .target = target,
        .version = version,
        .root_source_file = root_source_file,
    });
    tests.root_module.addImport("clap", clap_mod);

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
