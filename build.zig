const std = @import("std");

const zon: Zon = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const version = try std.SemanticVersion.parse(zon.version);

    const api_source_file = b.path("src/liza.zig");
    const root_source_file = b.path("src/main.zig");

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

    // Public API module
    const api_mod = b.addModule("liza", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = api_source_file,
    });

    // Root module
    const root_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = root_source_file,
        .strip = b.option(bool, "strip", "strip the binary"),
    });
    root_mod.addImport("argzon", argzon_mod);
    root_mod.addImport("zq", zq_mod);

    // Executable
    const exe_step = b.step("exe", "Install executable");

    const exe = b.addExecutable(.{
        .name = "liza",
        .version = version,
        .root_module = root_mod,
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

    // Documentation
    const docs_step = b.step("doc", "Emit documentation");

    const lib = b.addLibrary(.{
        .name = "liza",
        .version = version,
        .root_module = api_mod,
    });
    const docs_install = b.addInstallDirectory(.{
        .install_dir = .prefix,
        .install_subdir = "docs",
        .source_dir = lib.getEmittedDocs(),
    });
    docs_step.dependOn(&docs_install.step);
    install_step.dependOn(docs_step);

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

    // Compilation check for ZLS Build-On-Save
    // See: https://zigtools.org/zls/guides/build-on-save/
    const check_step = b.step("check", "Check compilation");
    const check_exe = b.addExecutable(.{
        .name = "liza",
        .version = version,
        .root_module = root_mod,
    });
    check_step.dependOn(&check_exe.step);

    // Release
    const release = b.step("release", "Install and archive release binaries");

    inline for (RELEASE_TRIPLES) |RELEASE_TRIPLE| {
        const RELEASE_NAME = "liza-v" ++ zon.version ++ "-" ++ RELEASE_TRIPLE;
        const IS_WINDOWS_RELEASE = comptime std.mem.endsWith(u8, RELEASE_TRIPLE, "windows");
        const RELEASE_EXE_ARCHIVE_BASENAME = RELEASE_NAME ++ if (IS_WINDOWS_RELEASE) ".zip" else ".tar.xz";

        const release_exe = b.addExecutable(.{
            .name = RELEASE_NAME,
            .version = version,
            .root_module = b.createModule(.{
                .target = b.resolveTargetQuery(try std.Build.parseTargetQuery(.{ .arch_os_abi = RELEASE_TRIPLE })),
                .optimize = .ReleaseSafe,
                .root_source_file = root_source_file,
                .strip = true,
            }),
        });
        release_exe.root_module.addImport("argzon", argzon_mod);
        release_exe.root_module.addImport("zq", zq_mod);

        const release_exe_install = b.addInstallArtifact(release_exe, .{});

        const release_exe_archive = b.addSystemCommand(if (IS_WINDOWS_RELEASE) &.{
            "zip",
            "-9",
        } else &.{
            "tar",
            "-cJf",
        });
        release_exe_archive.setCwd(release_exe.getEmittedBinDirectory());
        if (!IS_WINDOWS_RELEASE) release_exe_archive.setEnvironmentVariable("XZ_OPT", "-9");
        const release_exe_archive_path = release_exe_archive.addOutputFileArg(RELEASE_EXE_ARCHIVE_BASENAME);
        release_exe_archive.addArg(release_exe.out_filename);
        release_exe_archive.step.dependOn(&release_exe_install.step);

        const release_exe_archive_install = b.addInstallFileWithDir(
            release_exe_archive_path,
            .{ .custom = "release" },
            RELEASE_EXE_ARCHIVE_BASENAME,
        );
        release_exe_archive_install.step.dependOn(&release_exe_archive.step);

        release.dependOn(&release_exe_archive_install.step);
    }
}

const RELEASE_TRIPLES = .{
    "aarch64-macos",
    "x86_64-linux",
    "x86_64-windows",
};

const Zon = struct {
    name: enum { liza },
    version: []const u8,
    fingerprint: u64,
    minimum_zig_version: []const u8,
    dependencies: struct {
        argzon: Dependency,
        zq: Dependency,
    },
    paths: []const []const u8,

    const Dependency = struct { url: []const u8, hash: []const u8, lazy: bool = false };
};
