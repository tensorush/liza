const std = @import("std");

const zq = @import("zq");

const MAX_BUF_SIZE = 1 << 12;

// Common paths
const SRC = "src/";
const TEMPLATES = "templates/";

const LICENSE = "LICENSE";
const README = "README.md";

const BUILD_ZIG = "build.zig";
const BUILD_ZON = "build.zig.zon";

const GITIGNORE = ".gitignore";
const GITATTRIBUTES = ".gitattributes";

const TYPOS_CONFIG = "typos.toml";

const VALE_CONFIG = ".vale.ini";
const VALE_ACCEPT = "accept.txt";
const VALE_VOCABS = "styles/config/vocabularies/";
const VALE_VOCAB = "$p/";

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

const ALL_TYPOS_CONFIG = @embedFile(TEMPLATES ++ TYPOS_CONFIG);

const ALL_VALE_CONFIG = @embedFile(TEMPLATES ++ VALE_CONFIG);
const ALL_VALE_ACCEPT = @embedFile(TEMPLATES ++ VALE_VOCABS ++ VALE_VOCAB ++ VALE_ACCEPT);

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

pub const Template = enum {
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
    template: Template,
    runner: Runner,
    version: std.SemanticVersion,
    out_dir_path: []const u8,
    with_doc: bool,
    with_cov: bool,
    with_spell: bool,
    with_lint: bool,
    with_check: bool,
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

    try createGitFiles(with_cov, pckg_dir);
    try createLicenseFile(user_name, pckg_dir);

    if (template == .exe or template == .lib) {
        if (with_spell) try createTyposConfigFile(with_lint, pckg_dir);
        if (with_lint) try createValeConfigFiles(arena, pckg_name, pckg_dir);
    }

    switch (template) {
        .exe => {
            var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
            defer src_dir.close();

            const exe_core = try std.mem.concat(arena, u8, &.{ pckg_name, ".zig" });

            try createSourceFile(EXE_CLI, EXE_CLI_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(exe_core, EXE_CORE_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(EXE_ROOT, EXE_ROOT_TEXT, pckg_name, pckg_desc, src_dir);
            try createWorkflows(template, runner, with_doc, with_cov, with_spell, with_lint, pckg_dir);
            try createReadmeFile(EXE_README, pckg_name_with_prefix_opt, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, template, runner, pckg_name, user_hndl, version, with_doc, with_cov, with_spell, with_lint, with_check, zig_version, pckg_dir);
        },
        .lib => {
            var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
            defer src_dir.close();

            var example1_dir = try pckg_dir.makeOpenPath(EXAMPLE1, .{});
            defer example1_dir.close();

            var example2_dir = try pckg_dir.makeOpenPath(EXAMPLE2, .{});
            defer example2_dir.close();

            const lib_core = try std.mem.concat(arena, u8, &.{ pckg_name, ".zig" });

            try createSourceFile(lib_core, LIB_CORE_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(LIB_ROOT, LIB_ROOT_TEXT, pckg_name, pckg_desc, src_dir);
            try createSourceFile(EXE_ROOT, LIB_EXAMPLE1, pckg_name, pckg_desc, example1_dir);
            try createSourceFile(EXE_ROOT, LIB_EXAMPLE2, pckg_name, pckg_desc, example2_dir);
            try createWorkflows(template, runner, with_doc, with_cov, with_spell, with_lint, pckg_dir);
            try createReadmeFile(LIB_README, pckg_name_with_prefix_opt, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, template, runner, pckg_name, user_hndl, version, with_doc, with_cov, with_spell, with_lint, with_check, zig_version, pckg_dir);
        },
        .bld => {
            try createWorkflows(template, runner, with_doc, with_cov, with_spell, with_lint, pckg_dir);
            try createReadmeFile(BLD_README, pckg_name_with_prefix_opt, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, template, runner, pckg_name, user_hndl, version, with_doc, with_cov, with_spell, with_lint, with_check, zig_version, pckg_dir);
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
    dir: std.fs.Dir,
) !void {
    var file = try dir.createFile(README, .{});
    defer file.close();

    var file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var file_writer = file.writer(&file_buf);
    const writer = &file_writer.interface;

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
        try writer.print("{s}{s}", .{
            text[idx .. idx + i], switch (text[idx + i + 1]) {
                'x' => if (pckg_name_with_prefix_opt) |pckg_name_with_prefix| pckg_name_with_prefix else pckg_name,
                'p' => pckg_name,
                'd' => pckg_desc,
                'u' => user_hndl,
                'g' => switch (runner) {
                    .github => GITHUB,
                    .forgejo,
                    .woodpecker,
                    => CODEBERG,
                },
                'w' => switch (runner) {
                    .github => GITHUB_LATEST_RELEASE,
                    .forgejo,
                    .woodpecker,
                    => CODEBERG_LATEST_RELEASE,
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
    template: Template,
    runner: Runner,
    pckg_name: []const u8,
    user_hndl: []const u8,
    version: std.SemanticVersion,
    with_doc: bool,
    with_cov: bool,
    with_spell: bool,
    with_lint: bool,
    with_check: bool,
    zig_version: std.SemanticVersion,
    dir: std.fs.Dir,
) !void {
    inline for ([_]std.zig.Ast.Mode{ .zig, .zon }) |mode| {
        const text = switch (template) {
            .exe => if (mode == .zig) EXE_BUILD_ZIG else EXE_BUILD_ZON,
            .lib => if (mode == .zig) LIB_BUILD_ZIG else LIB_BUILD_ZON,
            .bld => if (mode == .zig) BLD_BUILD_ZIG else BLD_BUILD_ZON,
        };

        var file = try dir.createFile(if (mode == .zig) BUILD_ZIG else BUILD_ZON, .{});
        defer file.close();

        var file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var file_writer = file.writer(&file_buf);
        const writer = &file_writer.interface;

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'p' => try writer.writeAll(pckg_name),
                'u' => try writer.writeAll(user_hndl),
                'v' => try writer.print("{f}", .{version}),
                'z' => try writer.print("{f}", .{zig_version}),
                'g' => try writer.writeAll(switch (runner) {
                    .github => GITHUB,
                    .forgejo,
                    .woodpecker,
                    => CODEBERG,
                }),
                'd' => if (with_doc) {
                    try writer.writeAll(
                        \\
                        \\    // Documentation
                        \\    const docs_step = b.step("doc", "Emit documentation");
                        \\
                    );
                    if (template == .exe) {
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
                'c' => if (with_cov) try writer.writeAll(
                    \\
                    \\    // Source code coverage with Kcov
                    \\    const cov_step = b.step("cov", "Generate source code coverage with Kcov");
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
                's' => if (with_spell) try writer.writeAll(switch (mode) {
                    .zig => switch (text[idx + i + 2]) {
                        '1' =>
                        \\
                        \\
                        \\    const typos_dep_lazy = if (b.lazyDependency(b.fmt("typos_{t}_{t}", .{
                        \\        target.result.cpu.arch,
                        \\        target.result.os.tag,
                        \\    }), .{})) |typos_dep| typos_dep else return;
                        \\    const typos_path = typos_dep_lazy.path("typos");
                        ,
                        '2' =>
                        \\
                        \\    // Source code spelling check with Typos
                        \\    const spell_step = b.step("spell", "Check source code spelling with Typos");
                        \\
                        \\    const typos_run = std.Build.Step.Run.create(b, "typos");
                        \\    typos_run.addFileArg(typos_path);
                        \\    spell_step.dependOn(&typos_run.step);
                        \\    install_step.dependOn(spell_step);
                        \\
                        ,
                        else => unreachable,
                    },
                    .zon =>
                    \\
                    \\        .typos_x86_64_windows = .{
                    \\            .url = "https://github.com/crate-ci/typos/releases/download/v1.35.7/typos-v1.35.7-x86_64-pc-windows-msvc.zip",
                    \\            .hash = "N-V-__8AAEjUjwBTsUGYkZJpmC_urG6fjoejezLggl9uGXFO",
                    \\            .lazy = true,
                    \\        },
                    ,
                }),
                'l' => if (with_lint) try writer.writeAll(switch (mode) {
                    .zig => switch (text[idx + i + 2]) {
                        '1' =>
                        \\
                        \\
                        \\    const vale_dep_lazy = if (b.lazyDependency(b.fmt("vale_{t}_{t}", .{
                        \\        target.result.cpu.arch,
                        \\        target.result.os.tag,
                        \\    }), .{})) |vale_dep| vale_dep else return;
                        \\    const vale_path = vale_dep_lazy.path("vale");
                        ,
                        '2' =>
                        \\
                        \\    // Markup prose linting check with Vale
                        \\    const lint_step = b.step("lint", "Check markup prose linting with Vale");
                        \\
                        \\    const vale_run = std.Build.Step.Run.create(b, "vale");
                        \\    vale_run.addFileArg(vale_path);
                        \\    vale_run.addArgs(&.{
                        \\        "--output=line",
                        \\        "README.md",
                        \\    });
                        \\    lint_step.dependOn(&vale_run.step);
                        \\    install_step.dependOn(lint_step);
                        \\
                        ,
                        else => unreachable,
                    },
                    .zon =>
                    \\
                    \\        .vale_aarch64_macos = .{
                    \\            .url = "https://github.com/errata-ai/vale/releases/download/v3.12.0/vale_3.12.0_macOS_arm64.tar.gz",
                    \\            .hash = "N-V-__8AALZBSAL_y5UQ61KSqr9hWXpxLSz1CKJyu-5TPj9X",
                    \\            .lazy = true,
                    \\        },
                    \\        .vale_x86_64_macos = .{
                    \\            .url = "https://github.com/errata-ai/vale/releases/download/v3.12.0/vale_3.12.0_macOS_64-bit.tar.gz",
                    \\            .hash = "N-V-__8AAKToSwKI4S3a98FdD_AgsKjzdFDVDrV9XaEtvdnB",
                    \\            .lazy = true,
                    \\        },
                    \\        .vale_x86_64_linux = .{
                    \\            .url = "https://github.com/errata-ai/vale/releases/download/v3.12.0/vale_3.12.0_Linux_64-bit.tar.gz",
                    \\            .hash = "N-V-__8AAKxSSgKT7HYjJfIEnMS-kZzqfxy1HHgRZRdu2cJr",
                    \\            .lazy = true,
                    \\        },
                    \\        .vale_x86_64_windows = .{
                    \\            .url = "https://github.com/errata-ai/vale/releases/download/v3.12.0/vale_3.12.0_Windows_64-bit.zip",
                    \\            .hash = "N-V-__8AADTCUwImzBm3ajx5-J4vzGxBFZgxJhO-WIvqrG3o",
                    \\            .lazy = true,
                    \\        },
                    ,
                }),
                'k' => if (with_check) try writer.print(
                    \\
                    \\    // Build compilation check for ZLS Build-On-Save
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
                    template,
                    if (template == .exe) "Executable" else "Library",
                    pckg_name,
                    template,
                }),
                else => unreachable,
            }
            switch (text[idx + i + 1]) {
                's',
                'l',
                => if (mode == .zig) {
                    idx += 1;
                },
                else => {},
            }
        }
        try writer.writeAll(text[idx..]);

        try writer.flush();
    }

    const build_zon = try dir.readFileAllocOptions(arena, BUILD_ZON, MAX_BUF_SIZE, null, .of(u8), 0);

    const fingerprint = blk: {
        const zig_build = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
            "zig",
            "build",
        }, .cwd_dir = dir });
        const fp_idx = std.mem.lastIndexOfScalar(u8, zig_build.stderr, 'x') orelse return Error.NoFingerprint;
        break :blk zig_build.stderr[fp_idx - 1 .. fp_idx + 17];
    };

    var file = try dir.createFile(BUILD_ZON, .{});
    defer file.close();

    var file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var file_writer = file.writer(&file_buf);
    const writer = &file_writer.interface;

    try zq.processQuery(
        arena,
        build_zon,
        ".fingerprint",
        writer,
        .{ .set_value_opt = fingerprint },
    );

    try writer.flush();

    if (template == .exe) {
        _ = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
            "zig",
            "fetch",
            "--save",
            "git+https://codeberg.org/tensorush/argzon.git",
        }, .cwd_dir = dir });
    }
    if (template == .exe or template == .lib) {
        _ = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
            "zig",
            "fetch",
            "--save",
            "git+https://github.com/Games-by-Mason/tracy_zig.git",
        }, .cwd_dir = dir });
        _ = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
            "zig",
            "fetch",
            "--save",
            "git+https://codeberg.org/tensorush/liza.git",
        }, .cwd_dir = dir });
    }
    if (template == .bld) {
        _ = try std.process.Child.run(.{ .allocator = arena, .argv = &.{
            "zig",
            "fetch",
            try std.fmt.allocPrint(arena, "--save={s}", .{pckg_name}),
            try std.fmt.allocPrint(arena, "git+https://{s}/{s}/{s}.git#v{f}", .{
                switch (runner) {
                    .github => GITHUB,
                    .forgejo,
                    .woodpecker,
                    => CODEBERG,
                },
                user_hndl,
                pckg_name,
                version,
            }),
        }, .cwd_dir = dir });
    }
}

fn createWorkflows(
    template: Template,
    runner: Runner,
    with_doc: bool,
    with_cov: bool,
    with_spell: bool,
    with_lint: bool,
    dir: std.fs.Dir,
) !void {
    const workflows_dir_path, const all_ci_workflow, const all_cd_workflow = switch (runner) {
        .github => .{ GITHUB_WORKFLOWS, ALL_GITHUB_CI_WORKFLOW, ALL_GITHUB_CD_WORKFLOW },
        .forgejo => .{ FORGEJO_WORKFLOWS, ALL_FORGEJO_CI_WORKFLOW, ALL_FORGEJO_CD_WORKFLOW },
        .woodpecker => .{ WOODPECKER_WORKFLOWS, ALL_WOODPECKER_CI_WORKFLOW, ALL_WOODPECKER_CD_WORKFLOW },
    };

    var workflows_dir = try dir.makeOpenPath(workflows_dir_path, .{});
    defer workflows_dir.close();

    if (template == .exe and runner != .forgejo) {
        const exe_release_workflow = switch (runner) {
            .github => EXE_GITHUB_RELEASE_WORKFLOW,
            .woodpecker => EXE_WOODPECKER_RELEASE_WORKFLOW,
            .forgejo => unreachable,
        };

        var file = try workflows_dir.createFile(RELEASE_WORKFLOW, .{});
        defer file.close();

        var file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var file_writer = file.writer(&file_buf);
        const writer = &file_writer.interface;

        try writer.writeAll(exe_release_workflow);

        try writer.flush();
    }

    inline for (.{ CI_WORKFLOW, CD_WORKFLOW }, .{ all_ci_workflow, all_cd_workflow }) |path, text| {
        if (std.mem.startsWith(u8, path, "cd") and !with_doc) break;

        var file = try workflows_dir.createFile(path, .{});
        defer file.close();

        var file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var file_writer = file.writer(&file_buf);
        const writer = &file_writer.interface;

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'c' => if (with_cov and runner == .github) try writer.writeAll(
                    \\
                    \\
                    \\      - name: Set up Kcov
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
                's' => if (with_spell) try writer.writeAll(switch (runner) {
                    .github,
                    .forgejo,
                    =>
                    \\
                    \\
                    \\      - name: Run `spell` step
                    \\        run: zig build spell
                    ,
                    .woodpecker =>
                    \\
                    \\
                    \\  spell:
                    \\    image: tensorush/ziglang:latest
                    \\    pull: true
                    \\
                    \\    commands: zig build spell
                    ,
                }),
                'l' => if (with_lint) try writer.writeAll(switch (runner) {
                    .github,
                    .forgejo,
                    =>
                    \\
                    \\
                    \\      - name: Run `lint` step
                    \\        run: zig build lint
                    ,
                    .woodpecker =>
                    \\
                    \\
                    \\  lint:
                    \\    image: tensorush/ziglang:latest
                    \\    pull: true
                    \\
                    \\    commands: zig build lint
                    ,
                }),
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
    dir: std.fs.Dir,
) !void {
    var file = try dir.createFile(path, .{});
    defer file.close();

    var file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var file_writer = file.writer(&file_buf);
    const writer = &file_writer.interface;

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
    dir: std.fs.Dir,
) !void {
    var file = try dir.createFile(LICENSE, .{});
    defer file.close();

    var file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var file_writer = file.writer(&file_buf);
    const writer = &file_writer.interface;

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
    with_cov: bool,
    dir: std.fs.Dir,
) !void {
    inline for (.{ GITATTRIBUTES, GITIGNORE }, .{ ALL_GITATTRIBUTES, ALL_GITIGNORE }) |path, text| {
        var file = try dir.createFile(path, .{});
        defer file.close();

        var file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var file_writer = file.writer(&file_buf);
        const writer = &file_writer.interface;

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'c' => if (with_cov) try writer.writeAll(
                    \\
                    \\
                    \\# Kcov source code coverage artifacts
                    \\kcov-output/
                ),
                else => unreachable,
            }
        }
        try writer.writeAll(text[idx..]);

        try writer.flush();
    }
}

fn createTyposConfigFile(
    with_lint: bool,
    dir: std.fs.Dir,
) !void {
    var file = try dir.createFile(TYPOS_CONFIG, .{});
    defer file.close();

    var file_buf: [MAX_BUF_SIZE]u8 = undefined;
    var file_writer = file.writer(&file_buf);
    const writer = &file_writer.interface;

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, ALL_TYPOS_CONFIG[idx..], '$')) |i| : (idx += i + 2) {
        try writer.writeAll(ALL_TYPOS_CONFIG[idx .. idx + i]);
        switch (ALL_TYPOS_CONFIG[idx + i + 1]) {
            'l' => if (with_lint) try writer.writeAll(
                \\
                \\    # Vale styles
                \\    "styles/",
            ),
            else => unreachable,
        }
    }
    try writer.writeAll(ALL_TYPOS_CONFIG[idx..]);

    try writer.flush();
}

fn createValeConfigFiles(
    arena: std.mem.Allocator,
    pckg_name: []const u8,
    dir: std.fs.Dir,
) !void {
    {
        var file = try dir.createFile(VALE_CONFIG, .{});
        defer file.close();

        var file_buf: [MAX_BUF_SIZE]u8 = undefined;
        var file_writer = file.writer(&file_buf);
        const writer = &file_writer.interface;

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, ALL_VALE_CONFIG[idx..], '$')) |i| : (idx += i + 2) {
            try writer.writeAll(ALL_VALE_CONFIG[idx .. idx + i]);
            switch (ALL_VALE_CONFIG[idx + i + 1]) {
                'p' => try writer.writeAll(pckg_name),
                else => unreachable,
            }
        }
        try writer.writeAll(ALL_VALE_CONFIG[idx..]);

        try writer.flush();
    }
    {
        const vale_vocab = try std.mem.concat(arena, u8, &.{ VALE_VOCABS, pckg_name });

        var vale_vocab_dir = try dir.makeOpenPath(vale_vocab, .{});
        defer vale_vocab_dir.close();

        var file = try vale_vocab_dir.createFile(VALE_ACCEPT, .{});
        defer file.close();
    }
}
