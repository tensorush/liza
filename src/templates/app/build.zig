const std = @import("std");

pub fn build(b: *std.Build) !void {
    const version_str = "$v";
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/App.zig");
    const version = try std.SemanticVersion.parse(version_str);

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
        .target = target,
        .optimize = optimize,
        .app = b.createModule(.{
            .root_source_file = root_source_file,
            .imports = &.{.{ .name = "mach", .module = mach_mod }},
        }),
    });
    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_run.addArgs(args);
    }
    exe_step.dependOn(&exe_run.step);

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
