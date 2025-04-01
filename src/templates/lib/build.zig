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
    const lib_step = b.step("lib", "Install library");

    const lib = b.addLibrary(.{
        .name = "$p",
        .version = version,
        .root_module = root_mod,
    });

    const lib_install = b.addInstallArtifact(lib, .{});
    lib_step.dependOn(&lib_install.step);
    install_step.dependOn(lib_step);
$d
    // Example suite
    const examples_step = b.step("example", "Install example suite");
    const examples_run_step = b.step("example-run", "Run example suite");

    inline for (EXAMPLE_NAMES) |EXAMPLE_NAME| {
        const example = b.addExecutable(.{
            .name = EXAMPLE_NAME,
            .version = version,
            .root_module = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .root_source_file = b.path(EXAMPLES_DIR ++ EXAMPLE_NAME ++ "/main.zig"),
            }),
        });
        example.root_module.addImport("$p", root_mod);

        const example_install = b.addInstallArtifact(example, .{});
        examples_step.dependOn(&example_install.step);

        const example_run = b.addRunArtifact(example);
        examples_run_step.dependOn(&example_run.step);
    }

    install_step.dependOn(examples_step);
$s
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
}

const EXAMPLES_DIR = "examples/";

const EXAMPLE_NAMES = .{
    "example1",
    "example2",
};
