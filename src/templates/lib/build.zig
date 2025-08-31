const std = @import("std");

const manifest = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/root.zig");
    const version: std.SemanticVersion = try .parse(manifest.version);

    // Dependencies
    const tracy_dep = b.dependency("tracy", .{
        .target = target,
        .optimize = optimize,
    });
    const tracy_mod = tracy_dep.module("tracy");$s1$l1

    // Public root module
    const root_mod = b.addModule("$p", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
        .strip = b.option(bool, "strip", "Strip binary"),
        .imports = &.{
            .{ .name = "tracy", .module = tracy_mod },
        },
    });

    // Library
    const lib = b.addLibrary(.{
        .name = "$p",
        .version = version,
        .root_module = root_mod,
    });
    if (b.option(bool, "no-bin", "Skip emitting binary") orelse false) {
        install_step.dependOn(&lib.step);
    } else {
        b.installArtifact(lib);
    }
$d
    // Example suite
    const examples_step = b.step("run", "Run example suite");

    const example_opt = b.option(Example, "example", "Run example");

    inline for (comptime std.meta.tags(Example)) |EXAMPLE| {
        const example_exe = b.addExecutable(.{
            .name = @tagName(EXAMPLE),
            .version = version,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path(EXAMPLES_DIR ++ @tagName(EXAMPLE) ++ "/main.zig"),
                .imports = &.{
                    .{ .name = "$p", .module = root_mod },
                },
            }),
        });

        if (example_opt == null or example_opt.? == EXAMPLE) {
            const example_run = b.addRunArtifact(example_exe);
            examples_step.dependOn(&example_run.step);
        }
    }

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .root_module = root_mod,
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
            EXAMPLES_DIR,
        },
        .check = true,
    });
    fmt_step.dependOn(&fmt.step);
    install_step.dependOn(fmt_step);
$s2$l2$k}

const EXAMPLES_DIR = "examples/";

const Example = enum {
    example1,
    example2,
};
