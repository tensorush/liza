const std = @import("std");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version_str = "$v";
    const version = try std.SemanticVersion.parse(version_str);

    const root_source_file = b.path("src/App.zig");

    // Dependencies
    const mach_dep = b.dependency("mach", .{
        .target = target,
        .optimize = optimize,
    });
    const mach_mod = mach_dep.module("mach");

    // Root module
    const root_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });
    root_mod.addImport("mach", mach_mod);

    // Executable
    const exe_step = b.step("exe", "Install executable");

    const exe = @import("mach").addExecutable(mach_dep.builder, .{
        .name = "$p",
        .target = target,
        .optimize = optimize,
        .app = root_mod,
    });

    const exe_install = b.addInstallArtifact(exe, .{});
    exe_step.dependOn(&exe_install.step);
    install_step.dependOn(exe_step);

    const exe_run_step = b.step("run", "Run executable");

    const exe_run = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_run.addArgs(args);
    }
    exe_run_step.dependOn(&exe_run.step);

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .version = version,
        .root_module = root_mod,
    });

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
    install_step.dependOn(tests_step);

    // Formatting check
    const fmt_step = b.step("fmt", "Check formatting");

    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            "build.zig.zon",
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    install_step.dependOn(fmt_step);
}
