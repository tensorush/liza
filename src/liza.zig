const std = @import("std");

const zq = @import("zq");

const MAX_BUF_SIZE = 1 << 12;

// Common paths
const SRC = "src/";
const LICENSE = "LICENSE";
const README = "README.md";
const TEMPLATES = "templates/";
const BUILD_ZIG = "build.zig";
const BUILD_ZON = "build.zig.zon";
const GITIGNORE = ".gitignore";
const GITATTRIBUTES = ".gitattributes";

const EXAMPLES = "examples/";
const EXAMPLE1 = EXAMPLES ++ "example1/";
const EXAMPLE2 = EXAMPLES ++ "example2/";

const GITHUB = "github.com";
const GITHUB_LATEST_RELEASE = "latest/download";

const CODEBERG = "codeberg.org";
const CODEBERG_LATEST_RELEASE = "download/latest";

const CD_WORKFLOW = "cd.yaml";
const CI_WORKFLOW = "ci.yaml";
const RELEASE_WORKFLOW = "release.yaml";

const GITHUB_WORKFLOWS = ".github/workflows/";
const FORGEJO_WORKFLOWS = ".forgejo/workflows/";
const WOODPECKER_WORKFLOWS = ".woodpecker/";

// Custom paths
const EXE = "exe/";
const LIB = "lib/";
const BLD = "bld/";

const EXE_CLI = "cli.zon";
const EXE_CORE = "$p.zig";
const EXE_ROOT = "main.zig";
const LIB_CORE = "$p.zig";
const LIB_ROOT = "root.zig";

// Common templates
const ALL_LICENSE = @embedFile(TEMPLATES ++ LICENSE);
const ALL_GITIGNORE = @embedFile(TEMPLATES ++ GITIGNORE);
const ALL_GITATTRIBUTES = @embedFile(TEMPLATES ++ GITATTRIBUTES);
const ALL_GITHUB_CI_WORKFLOW = @embedFile(TEMPLATES ++ GITHUB_WORKFLOWS ++ CI_WORKFLOW);
const ALL_GITHUB_CD_WORKFLOW = @embedFile(TEMPLATES ++ GITHUB_WORKFLOWS ++ CD_WORKFLOW);
const ALL_FORGEJO_CI_WORKFLOW = @embedFile(TEMPLATES ++ FORGEJO_WORKFLOWS ++ CI_WORKFLOW);
const ALL_FORGEJO_CD_WORKFLOW = @embedFile(TEMPLATES ++ FORGEJO_WORKFLOWS ++ CD_WORKFLOW);
const ALL_WOODPECKER_CI_WORKFLOW = @embedFile(TEMPLATES ++ WOODPECKER_WORKFLOWS ++ CI_WORKFLOW);
const ALL_WOODPECKER_CD_WORKFLOW = @embedFile(TEMPLATES ++ WOODPECKER_WORKFLOWS ++ CD_WORKFLOW);

// Executable templates
const EXE_README = @embedFile(TEMPLATES ++ EXE ++ README);
const EXE_BUILD_ZIG = @embedFile(TEMPLATES ++ EXE ++ BUILD_ZIG);
const EXE_BUILD_ZON = @embedFile(TEMPLATES ++ EXE ++ BUILD_ZON);
const EXE_CLI_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_CLI);
const EXE_CORE_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_CORE);
const EXE_ROOT_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_ROOT);
const EXE_GITHUB_RELEASE_WORKFLOW = @embedFile(TEMPLATES ++ GITHUB_WORKFLOWS ++ RELEASE_WORKFLOW);
const EXE_WOODPECKER_RELEASE_WORKFLOW = @embedFile(TEMPLATES ++ WOODPECKER_WORKFLOWS ++ RELEASE_WORKFLOW);

// Library templates
const LIB_README = @embedFile(TEMPLATES ++ LIB ++ README);
const LIB_BUILD_ZIG = @embedFile(TEMPLATES ++ LIB ++ BUILD_ZIG);
const LIB_BUILD_ZON = @embedFile(TEMPLATES ++ LIB ++ BUILD_ZON);
const LIB_CORE_TEXT = @embedFile(TEMPLATES ++ LIB ++ SRC ++ LIB_CORE);
const LIB_ROOT_TEXT = @embedFile(TEMPLATES ++ LIB ++ SRC ++ LIB_ROOT);
const LIB_EXAMPLE1 = @embedFile(TEMPLATES ++ LIB ++ EXAMPLE1 ++ EXE_ROOT);
const LIB_EXAMPLE2 = @embedFile(TEMPLATES ++ LIB ++ EXAMPLE2 ++ EXE_ROOT);

// Build templates
const BLD_README = @embedFile(TEMPLATES ++ BLD ++ README);
const BLD_BUILD_ZIG = @embedFile(TEMPLATES ++ BLD ++ BUILD_ZIG);
const BLD_BUILD_ZON = @embedFile(TEMPLATES ++ BLD ++ BUILD_ZON);

const Error = error{
    NoFingerprint,
};

pub const Codebase = enum {
    exe,
    lib,
    bld,
};

pub const Runner = enum {
    github,
    forgejo,
    woodpecker,
};

pub fn initialize(
    arena: std.mem.Allocator,
    pckg_name_with_prefix_opt: ?[]const u8,
    pckg_name: []const u8,
    pckg_desc: []const u8,
    user_hndl: []const u8,
    user_name: []const u8,
    codebase: Codebase,
    runner: Runner,
    version: std.SemanticVersion,
    out_dir_path: []const u8,
    add_doc: bool,
    add_cov: bool,
    add_check: bool,
    zig_version: std.SemanticVersion,
) !void {
    var pckg_dir = blk: {
        var out_dir = try std.fs.cwd().openDir(out_dir_path, .{});
        defer out_dir.close();

        const pckg_dir_name = pckg_name_with_prefix_opt orelse pckg_name;
        _ = out_dir.access(pckg_dir_name, .{}) catch break :blk try out_dir.makeOpenPath(pckg_dir_name, .{});

        @panic("Directory already exists!");
    };
    defer pckg_dir.close();

    _ = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
        "git",
        "init",
    }, .cwd_dir = pckg_dir });

    try createGitFiles(add_cov, pckg_dir);
    try createLicenseFile(user_name, pckg_dir);

    switch (codebase) {
        .exe => {
            var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
            defer src_dir.close();

            const exe_core = try std.mem.concat(arena, u8, &.{ pckg_name, ".zig" });

            try createSourceFile(EXE_CLI, EXE_CLI_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(exe_core, EXE_CORE_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(EXE_ROOT, EXE_ROOT_TEXT, pckg_name, pckg_desc, src_dir);
            try createWorkflows(codebase, runner, add_doc, add_cov, pckg_dir);
            try createReadmeFile(EXE_README, pckg_name_with_prefix_opt, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, codebase, pckg_name, user_hndl, version, add_doc, add_cov, add_check, zig_version, pckg_dir);
        },
        .lib => {
            var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
            defer src_dir.close();

            var example1_dir = try pckg_dir.makeOpenPath(EXAMPLE1, .{});
            defer example1_dir.close();

            var example2_dir = try pckg_dir.makeOpenPath(EXAMPLE2, .{});
            defer example2_dir.close();

            const lib_core = try std.mem.concat(arena, u8, &.{ pckg_name, ".zig" });

            try createWorkflows(codebase, runner, add_doc, add_cov, pckg_dir);
            try createSourceFile(lib_core, LIB_CORE_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(LIB_ROOT, LIB_ROOT_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(EXE_ROOT, LIB_EXAMPLE1, pckg_name, pckg_desc, example1_dir);
            try createSourceFile(EXE_ROOT, LIB_EXAMPLE2, pckg_name, pckg_desc, example2_dir);
            try createReadmeFile(LIB_README, pckg_name_with_prefix_opt, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, codebase, pckg_name, user_hndl, version, add_doc, add_cov, add_check, zig_version, pckg_dir);
        },
        .bld => {
            try createWorkflows(codebase, runner, add_doc, add_cov, pckg_dir);
            try createReadmeFile(BLD_README, pckg_name_with_prefix_opt, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, codebase, pckg_name, user_hndl, version, add_doc, add_cov, add_check, zig_version, pckg_dir);
        },
    }
}

fn createReadmeFile(
    comptime text: []const u8,
    pckg_name_with_prefix_opt: ?[]const u8,
    pckg_name: []const u8,
    pckg_desc: []const u8,
    user_hndl: []const u8,
    runner: Runner,
    pckg_dir: std.fs.Dir,
) !void {
    var readme_file = try pckg_dir.createFile(README, .{});
    defer readme_file.close();

    var readme_file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var readme_file_writer = readme_file.writer(&readme_file_buf);
    const writer = &readme_file_writer.interface;

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
        try writer.print("{s}{s}", .{
            text[idx .. idx + i], switch (text[idx + i + 1]) {
                // ### Setup
                // > [!NOTE]
                // > On Windows, make sure to allow running scripts:
                // >
                // > ```powershell
                // > Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
                // > ```
                // ```sh
                // ./zig/download.ps1
                // ```
                'x' => if (pckg_name_with_prefix_opt) |pckg_name_with_prefix| pckg_name_with_prefix else pckg_name,
                'p' => pckg_name,
                'd' => pckg_desc,
                'u' => user_hndl,
                'g' => switch (runner) {
                    .github => GITHUB,
                    .forgejo, .woodpecker => CODEBERG,
                },
                'l' => switch (runner) {
                    .github => GITHUB_LATEST_RELEASE,
                    .forgejo, .woodpecker => CODEBERG_LATEST_RELEASE,
                },
                else => unreachable,
            },
        });
    }
    try writer.writeAll(text[idx..]);

    try writer.flush();
}

fn createBuildFiles(
    arena: std.mem.Allocator,
    codebase: Codebase,
    pckg_name: []const u8,
    user_hndl: []const u8,
    version: std.SemanticVersion,
    add_doc: bool,
    add_cov: bool,
    add_check: bool,
    zig_version: std.SemanticVersion,
    pckg_dir: std.fs.Dir,
) !void {
    inline for (.{ std.zig.Ast.Mode.zig, std.zig.Ast.Mode.zon }) |mode| {
        const text = switch (codebase) {
            .exe => if (mode == .zig) EXE_BUILD_ZIG else EXE_BUILD_ZON,
            .lib => if (mode == .zig) LIB_BUILD_ZIG else LIB_BUILD_ZON,
            .bld => if (mode == .zig) BLD_BUILD_ZIG else BLD_BUILD_ZON,
        };

        var build_file = try pckg_dir.createFile(if (mode == .zig) BUILD_ZIG else BUILD_ZON, .{});
        defer build_file.close();

        var build_file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var build_file_writer = build_file.writer(&build_file_buf);
        const writer = &build_file_writer.interface;

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'p' => try writer.writeAll(pckg_name),
                'u' => try writer.writeAll(user_hndl),
                'v' => try writer.print("{f}", .{version}),
                'z' => try writer.print("{f}", .{zig_version}),
                'd' => if (add_doc) {
                    try writer.writeAll(
                        \\
                        \\    // Documentation
                        \\    const docs_step = b.step("doc", "Emit documentation");
                        \\
                    );
                    if (codebase == .exe) {
                        try writer.print(
                            \\
                            \\    const lib = b.addLibrary(.{{
                            \\        .name = "{s}",
                            \\        .version = version,
                            \\        .root_module = api_mod,
                            \\    }});
                        , .{pckg_name});
                    }
                    try writer.writeAll(
                        \\
                        \\    const docs_install = b.addInstallDirectory(.{
                        \\        .install_dir = .prefix,
                        \\        .install_subdir = "docs",
                        \\        .source_dir = lib.getEmittedDocs(),
                        \\    });
                        \\    docs_step.dependOn(&docs_install.step);
                        \\
                    );
                },
                'c' => if (add_cov) try writer.writeAll(
                    \\
                    \\    // Code coverage
                    \\    const cov_step = b.step("cov", "Generate code coverage");
                    \\
                    \\    const cov_run = b.addSystemCommand(&.{
                    \\        "kcov",
                    \\        "--clean",
                    \\        "--include-pattern=src/",
                    \\        "kcov-output/",
                    \\    });
                    \\    cov_run.addArtifactArg(tests);
                    \\    cov_step.dependOn(&cov_run.step);
                    \\
                ),
                'k' => if (add_check) try writer.print(
                    \\
                    \\    // Compilation check for ZLS Build-On-Save
                    \\    // See: https://zigtools.org/zls/guides/build-on-save/
                    \\    const check_step = b.step("check", "Check compilation");
                    \\    const check_{t} = b.add{s}(.{{
                    \\        .name = "{s}",
                    \\        .version = version,
                    \\        .root_module = root_mod,
                    \\    }});
                    \\    check_step.dependOn(&check_{t}.step);
                    \\
                , .{
                    codebase,
                    if (codebase == .exe) "Executable" else "Library",
                    pckg_name,
                    codebase,
                }),
                else => unreachable,
            }
        }
        try writer.writeAll(text[idx..]);

        try writer.flush();

        if (mode == .zon) {
            const build_zon = try pckg_dir.readFileAllocOptions(arena, BUILD_ZON, MAX_BUF_SIZE, null, .of(u8), 0);

            const fingerprint = blk: {
                const zig_build = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
                    "zig",
                    "build",
                }, .cwd_dir = pckg_dir });
                const fp_idx = std.mem.lastIndexOfScalar(u8, zig_build.stderr, 'x') orelse return Error.NoFingerprint;
                break :blk zig_build.stderr[fp_idx - 1 .. fp_idx + 17];
            };

            var new_build_file = try pckg_dir.createFile(BUILD_ZON, .{});
            defer new_build_file.close();

            var new_build_file_buf: [MAX_BUF_SIZE]u8 = undefined;
            var new_build_file_writer = new_build_file.writer(&new_build_file_buf);
            const new_writer = &new_build_file_writer.interface;

            try zq.processQuery(
                arena,
                build_zon,
                ".fingerprint",
                new_writer,
                .{ .set_value_opt = fingerprint },
            );

            try new_writer.flush();

            if (codebase == .exe) {
                _ = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
                    "zig",
                    "fetch",
                    "--save",
                    "git+https://codeberg.org/tensorush/argzon.git",
                }, .cwd_dir = pckg_dir });
            }
        }
    }
}

fn createWorkflows(
    codebase: Codebase,
    runner: Runner,
    add_doc: bool,
    add_cov: bool,
    pckg_dir: std.fs.Dir,
) !void {
    const workflows_dir_path, const all_ci_workflow, const all_cd_workflow = switch (runner) {
        .github => .{ GITHUB_WORKFLOWS, ALL_GITHUB_CI_WORKFLOW, ALL_GITHUB_CD_WORKFLOW },
        .forgejo => .{ FORGEJO_WORKFLOWS, ALL_FORGEJO_CI_WORKFLOW, ALL_FORGEJO_CD_WORKFLOW },
        .woodpecker => .{ WOODPECKER_WORKFLOWS, ALL_WOODPECKER_CI_WORKFLOW, ALL_WOODPECKER_CD_WORKFLOW },
    };

    var workflows_dir = try pckg_dir.makeOpenPath(workflows_dir_path, .{});
    defer workflows_dir.close();

    if (codebase == .exe and runner != .forgejo) {
        const exe_release_workflow = switch (runner) {
            .github => EXE_GITHUB_RELEASE_WORKFLOW,
            .woodpecker => EXE_WOODPECKER_RELEASE_WORKFLOW,
            .forgejo => unreachable,
        };

        var workflow_file = try workflows_dir.createFile(RELEASE_WORKFLOW, .{});
        defer workflow_file.close();

        var workflow_file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var workflow_file_writer = workflow_file.writer(&workflow_file_buf);
        const writer = &workflow_file_writer.interface;

        try writer.writeAll(exe_release_workflow);

        try writer.flush();
    }

    inline for (.{ CI_WORKFLOW, CD_WORKFLOW }, .{ all_ci_workflow, all_cd_workflow }) |path, text| {
        if (std.mem.startsWith(u8, path, "cd") and !add_doc) break;

        var workflow_file = try workflows_dir.createFile(path, .{});
        defer workflow_file.close();

        var workflow_file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var workflow_file_writer = workflow_file.writer(&workflow_file_buf);
        const writer = &workflow_file_writer.interface;

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'c' => if (add_cov and runner == .github) try writer.writeAll(
                    \\
                    \\
                    \\      - name: Set up kcov
                    \\        run: sudo apt install kcov
                    \\
                    \\      - name: Run `cov` step
                    \\        run: zig build cov
                    \\
                    \\      - name: Upload coverage to Codecov
                    \\        uses: codecov/codecov-action@v5
                    \\        with:
                    \\          token: ${{ secrets.CODECOV_TOKEN }}
                    \\          directory: kcov-output/
                    \\          fail_ci_if_error: true
                    \\          verbose: true
                ),
                else => try writer.writeAll(text[idx + i .. idx + i + 2]),
            }
        }
        try writer.writeAll(text[idx..]);

        try writer.flush();
    }
}

fn createSourceFile(
    path: []const u8,
    text: []const u8,
    pckg_name: []const u8,
    pckg_desc: []const u8,
    src_dir: std.fs.Dir,
) !void {
    var src_file = try src_dir.createFile(path, .{});
    defer src_file.close();

    var src_file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var src_file_writer = src_file.writer(&src_file_buf);
    const writer = &src_file_writer.interface;

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
        try writer.print("{s}{s}", .{
            text[idx .. idx + i], switch (text[idx + i + 1]) {
                'p' => pckg_name,
                'd' => pckg_desc,
                else => unreachable,
            },
        });
    }
    try writer.writeAll(text[idx..]);

    try writer.flush();
}

fn createLicenseFile(
    user_name: []const u8,
    pckg_dir: std.fs.Dir,
) !void {
    var license_file = try pckg_dir.createFile(LICENSE, .{});
    defer license_file.close();

    var license_file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var license_file_writer = license_file.writer(&license_file_buf);
    const writer = &license_file_writer.interface;

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, ALL_LICENSE[idx..], '$')) |i| : (idx += i + 2) {
        try writer.writeAll(ALL_LICENSE[idx .. idx + i]);
        switch (ALL_LICENSE[idx + i + 1]) {
            'y' => try writer.print("{d}", .{blk: {
                const now = std.time.epoch.EpochSeconds{ .secs = @intCast(std.time.timestamp()) };
                break :blk now.getEpochDay().calculateYearDay().year;
            }}),
            'n' => try writer.writeAll(user_name),
            else => unreachable,
        }
    }
    try writer.writeAll(ALL_LICENSE[idx..]);

    try writer.flush();
}

fn createGitFiles(
    add_cov: bool,
    dir: std.fs.Dir,
) !void {
    inline for (.{ GITATTRIBUTES, GITIGNORE }, .{ ALL_GITATTRIBUTES, ALL_GITIGNORE }) |path, text| {
        var git_file = try dir.createFile(path, .{});
        defer git_file.close();

        var git_file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var git_file_writer = git_file.writer(&git_file_buf);
        const writer = &git_file_writer.interface;

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'c' => if (add_cov) try writer.writeAll(
                    \\
                    \\
                    \\# Kcov artifacts
                    \\kcov-output/
                ),
                else => unreachable,
            }
        }
        try writer.writeAll(text[idx..]);

        try writer.flush();
    }
}
