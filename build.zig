const std = @import("std");

const manifest: struct {
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
} = @import("build.zig.zon");

pub fn build(b: *std.Build) !void {
    const install_step = b.getInstallStep();
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const version = try std.SemanticVersion.parse(manifest.version);

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
    const zq_art = zq_dep.artifact("zq");

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
        .strip = b.option(bool, "strip", "Strip the binary"),
    });
    root_mod.addImport("argzon", argzon_mod);
    root_mod.addImport("zq", zq_mod);

    // Executable
    const exe_run_step = b.step("run", "Run executable");

    const exe = b.addExecutable(.{
        .name = "liza",
        .version = version,
        .root_module = root_mod,
    });
    b.installArtifact(exe);

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

    // Minimum Zig version update
    const mzv_step = b.step("mzv", "Update minimum Zig version");

    const mzv_run = b.addRunArtifact(zq_art);
    mzv_run.addArgs(&.{
        "--io",
        "build.zig.zon",
        "-s",
        std.mem.trimRight(u8, b.run(&.{ b.graph.zig_exe, "version" }), "\n"),
        "-q",
        ".minimum_zig_version",
    });
    mzv_step.dependOn(&mzv_run.step);
    install_step.dependOn(mzv_step);

    // Next version tag
    const tag_step = b.step("tag", "Tag next version");

    const bump = b.option(enum { major, minor, patch }, "bump", "Bump version number part") orelse .patch;
    const message = b.option([]const u8, "message", "Git commit and tag message") orelse b.fmt("chore: bump {s} version", .{@tagName(bump)});

    var next_version = version;
    switch (bump) {
        inline else => |tag| @field(next_version, @tagName(tag)) += 1,
    }
    switch (bump) {
        .major => {
            next_version.minor = 0;
            next_version.patch = 0;
        },
        .minor => next_version.patch = 0,
        .patch => {},
    }

    const next_version_run = b.addRunArtifact(zq_art);
    next_version_run.addArgs(&.{
        "--io",
        "build.zig.zon",
        "-s",
        b.fmt("{}", .{next_version}),
        "-q",
        ".version",
    });

    const git_add_bump_run = b.addSystemCommand(&.{
        "git",
        "add",
        "-A",
    });
    git_add_bump_run.step.dependOn(&next_version_run.step);

    const git_commit_bump_run = b.addSystemCommand(&.{
        "git",
        "commit",
        "-m",
        message,
    });
    git_commit_bump_run.step.dependOn(&git_add_bump_run.step);

    const git_tag_bump_run = b.addSystemCommand(&.{
        "git",
        "tag",
        b.fmt("v{}", .{next_version}),
        "-m",
        message,
    });
    git_tag_bump_run.step.dependOn(&git_commit_bump_run.step);

    tag_step.dependOn(&git_tag_bump_run.step);

    // Release
    const release = b.step("release", "Install and archive release binaries");

    inline for (RELEASE_TRIPLES) |RELEASE_TRIPLE| {
        const RELEASE_NAME = "liza-v" ++ manifest.version ++ "-" ++ RELEASE_TRIPLE;
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
