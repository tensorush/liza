const std = @import("std");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version_str = "$v";
    const version = try std.SemanticVersion.parse(version_str);

    const root_source_file = b.path("src/root.zig");

    // Public root module
    const root_mod = b.addModule("$p", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
    });

    // Library
    const lib = b.addLibrary(.{
        .name = "$p",
        .version = version,
        .root_module = root_mod,
    });
    b.installArtifact(lib);
$d
    // Example suite
    const example_run_step = b.step("run", "Run example suite");

    const example_opt = b.option(Example, "example", "Run example");

    inline for (comptime std.meta.tags(Example)) |EXAMPLE| {
        const example_exe = b.addExecutable(.{
            .name = @tagName(EXAMPLE),
            .version = version,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path(EXAMPLES_DIR ++ @tagName(EXAMPLE) ++ "/main.zig"),
            }),
        });
        example_exe.root_module.addImport("$p", root_mod);
        b.installArtifact(example_exe);

        if (example_opt == null or example_opt.? == EXAMPLE) {
            const example_run = b.addRunArtifact(example_exe);
            example_run_step.dependOn(&example_run.step);
        }
    }

    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .version = version,
        .root_module = root_mod,
    });

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
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
$k}

const EXAMPLES_DIR = "examples/";

const Example = enum {
    example1,
    example2,
};
