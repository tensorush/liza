const std = @import("std");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/main.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 7, .patch = 0 };

    // Dependencies
    const argzon_dep = b.dependency("argzon", .{
        .target = target,
        .optimize = optimize,
    });
    const argzon_mod = argzon_dep.module("argzon");

    const zq_dep = b.dependency("zq", .{
        .target = target,
        .optimize = optimize,
    });
    const zq_mod = zq_dep.module("zq");

    // Executable
    const exe_step = b.step("exe", "Run executable");

    const exe = b.addExecutable(.{
        .name = "liza",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = root_source_file,
        }),
    });
    exe.root_module.addImport("argzon", argzon_mod);
    exe.root_module.addImport("zq", zq_mod);
    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_run.addArgs(args);
    }
    exe_step.dependOn(&exe_run.step);

    // Formatting check
    const fmt_step = b.step("fmt", "Check formatting");

    const fmt = b.addFmt(.{
        .paths = &.{
            "src/",
            "build.zig",
            "build.zig.zon",
        },
        .exclude_paths = &.{
            "src/templates/exe/build.zig",
            "src/templates/exe/src/main.zig",
            "src/templates/exe/build.zig.zon",

            "src/templates/lib/build.zig",
            "src/templates/lib/src/root.zig",
            "src/templates/lib/build.zig.zon",
            "src/templates/lib/examples/example1/main.zig",
            "src/templates/lib/examples/example2/main.zig",

            "src/templates/bld/build.zig",
            "src/templates/bld/build.zig.zon",

            "src/templates/app/build.zig",
            "src/templates/app/build.zig.zon",
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    install_step.dependOn(fmt_step);
}
