const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/App.zig");
    const version = std.SemanticVersion{$v};

    // Dependencies
    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
    });
    const mach_mod = mach_dep.module("mach");

    // Executable
    const exe_step = b.step("exe", "Run executable");

    const exe = @import("mach").addExecutable(mach_dep.builder, .{
        .name = "$p",
        // Remove target in favor of app's target when Mach does
        .target = target,
        // Add version when Mach does
        // .version = version,
        // Remove optimize in favor of app's optimize when Mach does
        .optimize = optimize,
        .app = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = root_source_file,
            // Remove imports in favor of exe.addImport() when Mach supports it
            .imports = &.{.{ .name = "mach", .module = mach_mod }},
        }),
    });
    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_run.addArgs(args);
    }
    exe_step.dependOn(&exe_run.step);
    b.default_step.dependOn(exe_step);

    // Documentation
    const docs_step = b.step("doc", "Emit documentation");

    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = exe.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    b.default_step.dependOn(docs_step);

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .root_source_file = root_source_file,
        }),
    });
    tests.root_module.addImport("mach", mach_mod);

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
