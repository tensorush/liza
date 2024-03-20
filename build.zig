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
        .name = "liza",
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

    // Lints
    const lints_step = b.step("lints", "Run lints");

    const lints = b.addFmt(.{
        .paths = &.{ "src/", "build.zig" },
        .check = true,
    });
    lints_step.dependOn(&lints.step);
    b.default_step.dependOn(lints_step);
}
