const std = @import("std");

const liza = @import("liza");

const manifest = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const api_source_file = b.path("src/$p.zig");
    const root_source_file = b.path("src/main.zig");
    const version: std.SemanticVersion = try .parse(manifest.version);

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
    const zq_art = zq_dep.artifact("zq");

    const tracy_dep = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
    });
    const tracy_mod = tracy_dep.module("tracy");
    const tracy_impl_mod = tracy_dep.module(if (b.option(bool, "profile", "Profile binary with Tracy") orelse false)
        "tracy_impl_enabled"
    else
        "tracy_impl_disabled");$s1$l1

    // Public API module
    const api_mod = b.addModule("$p", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = api_source_file,
        .strip = b.option(bool, "strip", "Strip binary"),
    });

    // Private root module
    const root_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
        .strip = api_mod.strip,
        .imports = &.{
            .{ .name = "argzon", .module = argzon_mod },
            .{ .name = "tracy", .module = tracy_mod },
            .{ .name = "tracy_impl", .module = tracy_impl_mod },
        },
    });

    // Executable
    const exe_run_step = b.step("run", "Run executable");

    const exe = b.addExecutable(.{
        .name = "$p",
        .version = version,
        .root_module = root_mod,
    });
    if (b.option(bool, "no-bin", "Skip emitting binary") orelse false) {
        install_step.dependOn(&exe.step);
    } else {
        b.installArtifact(exe);
    }

    const exe_run = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_run.addArgs(args);
    }
    exe_run_step.dependOn(&exe_run.step);
$d
    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .root_module = api_mod,
    });

    const tests_run = b.addRunArtifact(tests);
    if (b.option(bool, "debug", "Debug test suite with LLDB") orelse false) {
        // LLDB Zig config: https://github.com/ziglang/zig/blob/master/tools/lldb_pretty_printers.py#L2-L6
        const lldb_run = b.addSystemCommand(&.{
            "lldb",
            "--",
        });
        lldb_run.addArtifactArg(tests);
        tests_step.dependOn(&lldb_run.step);
    } else {
        tests_step.dependOn(&tests_run.step);
    }
    install_step.dependOn(tests_step);
$c
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
$s2$l2$k
    // Next version tag with Zq
    liza.tag(b, zq_art, version);

    // Dependencies and minimum Zig version update with Zq
    liza.update(b, zq_art, manifest.dependencies);

    // Archived binary release with Tar (Unix) and Zip (Windows)
    try liza.release(b, liza.RELEASE_TRIPLES, manifest, .ReleaseSafe, root_source_file, &.{
        .{ .name = "argzon", .module = argzon_mod },
    });
}
