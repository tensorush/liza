const std = @import("std");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const root_source_file = b.path("src/main.zig");
    const version = std.SemanticVersion{$v};

    // Dependencies
    const argzon_dep = b.dependency("argzon", .{
        .target = target,
        .optimize = optimize,
    });
    const argzon_mod = argzon_dep.module("argzon");

    // Executable
    const exe_step = b.step("exe", "Run executable");

    const exe = b.addExecutable(.{
        .name = "$p",
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .root_source_file = root_source_file,
        }),
    });
    exe.root_module.addImport("argzon", argzon_mod);
    b.installArtifact(exe);

    const exe_run = b.addRunArtifact(exe);
    if (b.args) |args| {
        exe_run.addArgs(args);
    }
    exe_step.dependOn(&exe_run.step);
$d
    // Test suite
    const tests_step = b.step("test", "Run test suite");

    const tests = b.addTest(.{
        .version = version,
        .root_module = b.createModule(.{
            .target = target,
            .root_source_file = root_source_file,
        }),
    });
    tests.root_module.addImport("argzon", argzon_mod);

    const tests_run = b.addRunArtifact(tests);
    tests_step.dependOn(&tests_run.step);
    install_step.dependOn(tests_step);
$c
    // Binary release
    const release = b.step("release", "Install release binaries");

    inline for (RELEASE_TRIPLES) |RELEASE_TRIPLE| {
        const release_exe = b.addExecutable(.{
            .name = "$p-" ++ RELEASE_TRIPLE,
            .version = version,
            .root_module = b.createModule(.{
                .target = b.resolveTargetQuery(try std.Build.parseTargetQuery(.{ .arch_os_abi = RELEASE_TRIPLE })),
                .optimize = .ReleaseSafe,
                .root_source_file = root_source_file,
            }),
        });
        release_exe.root_module.addImport("argzon", argzon_mod);

        const release_exe_install = b.addInstallArtifact(release_exe, .{});
        release.dependOn(&release_exe_install.step);
    }

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

const RELEASE_TRIPLES = .{
    "aarch64-linux",
    "aarch64-macos",
    "x86_64-linux",
    "x86_64-macos",
    "x86_64-windows",
};
