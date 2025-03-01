const std = @import("std");

pub fn build(b: *std.Build) void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/main.zig");
    const version = std.SemanticVersion{ .major = 0, .minor = 6, .patch = 1 };

    // Dependencies
    // const zq_dep = b.dependency("zq", .{
    //     .target = target,
    //     .optimize = optimize,
    // });
    // const zq_art = zq_dep.artifact("zq");

    const clap_dep = b.dependency("clap", .{
        .target = target,
        .optimize = optimize,
    });
    const clap_mod = clap_dep.module("clap");

    const zeit_dep = b.dependency("zeit", .{
        .target = target,
        .optimize = optimize,
    });
    const zeit_mod = zeit_dep.module("zeit");

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
    exe.root_module.addImport("clap", clap_mod);
    exe.root_module.addImport("zeit", zeit_mod);
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

    // Fingerprint
    // const fingerprint_step = b.step("fingerprint", "Initialize fingerprint");

    // const zig_bin_path = try zq_art.getEmittedBin().getPath3(b, fingerprint_step).toString(b.allocator);

    // const fingerprint_run = b.addSystemCommand(&.{});
    // fingerprint_run.addArgs(&.{
    //     "-i",
    //     "build.zig.zon",
    //     "-o",
    //     "build.zig.zon",
    //     "-s",
    //     "$(zig build 2>&1 >/dev/null | grep -o '0xf[^ ]*' | tail -n 1)",
    //     ".fingerprint",
    // });
    // fingerprint_step.dependOn(&fingerprint_run.step);
}
