const std = @import("std");

const zq = @import("zq");
const zeit = @import("zeit");

// Common paths
const SRC = "src/";
const LICENSE = "LICENSE";
const README = "README.md";
const TEMPLATES = "templates/";
const BUILD_ZIG = "build.zig";
const BUILD_ZON = "build.zig.zon";

const EXAMPLES = "examples/";
const EXAMPLE1 = EXAMPLES ++ "example1/";
const EXAMPLE2 = EXAMPLES ++ "example2/";

const GITHUB = "github.com";
const CODEBERG = "codeberg.org";
const CD_WORKFLOW = "cd.yaml";
const CI_WORKFLOW = "ci.yaml";
const GITIGNORE = ".gitignore";
const GITATTRIBUTES = ".gitattributes";
const GITHUB_WORKFLOWS = ".github/workflows/";
const FORGEJO_WORKFLOWS = ".forgejo/workflows/";
const WOODPECKER_WORKFLOWS = ".woodpecker/";

// Custom paths
const EXE = "exe/";
const LIB = "lib/";
const BLD = "bld/";
const APP = "app/";

const EXE_CI_STEP = "exe";
const LIB_CI_STEP = "example";
const BLD_CI_STEP = "lib";
const APP_CI_STEP = "exe";

const EXE_CORE = "$p.zig";
const EXE_ROOT = "main.zig";
const LIB_CORE = "$p.zig";
const LIB_ROOT = "root.zig";
const APP_ROOT = "App.zig";
const APP_SHADER = "shader.wgsl";

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
const EXE_CORE_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_CORE);
const EXE_ROOT_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_ROOT);

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

// App templates
const APP_README = @embedFile(TEMPLATES ++ APP ++ README);
const APP_BUILD_ZIG = @embedFile(TEMPLATES ++ APP ++ BUILD_ZIG);
const APP_BUILD_ZON = @embedFile(TEMPLATES ++ APP ++ BUILD_ZON);
const APP_ROOT_TEXT = @embedFile(TEMPLATES ++ APP ++ SRC ++ APP_ROOT);
const APP_SHADER_TEXT = @embedFile(TEMPLATES ++ APP ++ SRC ++ APP_SHADER);

pub const Codebase = enum {
    exe,
    lib,
    bld,
    app,
};

pub const Runner = enum {
    github,
    forgejo,
    woodpecker,
};

pub fn initialize(
    arena: std.mem.Allocator,
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
    zig_version: std.SemanticVersion,
) !void {
    var pckg_dir = blk: {
        const out_dir = try std.fs.cwd().openDir(out_dir_path, .{});
        _ = out_dir.access(pckg_name, .{}) catch break :blk try out_dir.makeOpenPath(pckg_name, .{});
        @panic("Directory already exists!");
    };
    defer pckg_dir.close();

    _ = try std.process.Child.run(.{ .allocator = arena, .argv = &.{ "git", "init" }, .cwd_dir = pckg_dir });

    try createGitFiles(add_cov, pckg_dir);
    try createLicenseFile(user_name, pckg_dir);

    switch (codebase) {
        .exe => {
            var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
            defer src_dir.close();

            const exe_core = try std.mem.concat(arena, u8, &.{ pckg_name, ".zig" });

            try createSourceFile(exe_core, EXE_CORE_TEXT, pckg_name, src_dir);
            try createSourceFile(EXE_ROOT, EXE_ROOT_TEXT, pckg_name, src_dir);
            try createWorkflows(EXE_CI_STEP, runner, add_doc, add_cov, zig_version, pckg_dir);
            try createReadmeFile(EXE_README, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, codebase, pckg_name, user_hndl, version, add_doc, add_cov, zig_version, pckg_dir);
        },
        .lib => {
            var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
            defer src_dir.close();

            var example1_dir = try pckg_dir.makeOpenPath(EXAMPLE1, .{});
            defer example1_dir.close();

            var example2_dir = try pckg_dir.makeOpenPath(EXAMPLE2, .{});
            defer example2_dir.close();

            const lib_core = try std.mem.concat(arena, u8, &.{ pckg_name, ".zig" });

            try createSourceFile(lib_core, LIB_CORE_TEXT, pckg_name, src_dir);
            try createSourceFile(LIB_ROOT, LIB_ROOT_TEXT, pckg_name, src_dir);
            try createSourceFile(EXE_ROOT, LIB_EXAMPLE1, pckg_name, example1_dir);
            try createSourceFile(EXE_ROOT, LIB_EXAMPLE2, pckg_name, example2_dir);
            try createWorkflows(LIB_CI_STEP, runner, add_doc, add_cov, zig_version, pckg_dir);
            try createReadmeFile(LIB_README, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, codebase, pckg_name, user_hndl, version, add_doc, add_cov, zig_version, pckg_dir);
        },
        .bld => {
            try createWorkflows(BLD_CI_STEP, runner, add_doc, add_cov, zig_version, pckg_dir);
            try createReadmeFile(BLD_README, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, codebase, pckg_name, user_hndl, version, add_doc, add_cov, zig_version, pckg_dir);
        },
        .app => {
            var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
            defer src_dir.close();

            try createSourceFile(APP_ROOT, APP_ROOT_TEXT, pckg_name, src_dir);
            try createSourceFile(APP_SHADER, APP_SHADER_TEXT, pckg_name, src_dir);
            try createWorkflows(APP_CI_STEP, runner, add_doc, add_cov, zig_version, pckg_dir);
            try createReadmeFile(APP_README, pckg_name, pckg_desc, user_hndl, runner, pckg_dir);
            try createBuildFiles(arena, codebase, pckg_name, user_hndl, version, add_doc, add_cov, zig_version, pckg_dir);
        },
    }
}

fn createReadmeFile(
    comptime text: []const u8,
    pckg_name: []const u8,
    pckg_desc: []const u8,
    user_hndl: []const u8,
    runner: Runner,
    pckg_dir: std.fs.Dir,
) !void {
    var readme_file = try pckg_dir.createFile(README, .{});
    const readme_writer = readme_file.writer();
    defer readme_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
        try readme_writer.writeAll(text[idx .. idx + i]);
        switch (text[idx + i + 1]) {
            'p' => try readme_writer.writeAll(pckg_name),
            'd' => try readme_writer.writeAll(pckg_desc),
            'u' => try readme_writer.writeAll(user_hndl),
            'g' => try readme_writer.writeAll(switch (runner) {
                .github => GITHUB,
                .forgejo, .woodpecker => CODEBERG,
            }),
            else => unreachable,
        }
    }
    try readme_writer.writeAll(text[idx..]);
}

fn createBuildFiles(
    arena: std.mem.Allocator,
    codebase: Codebase,
    pckg_name: []const u8,
    user_hndl: []const u8,
    version: std.SemanticVersion,
    add_doc: bool,
    add_cov: bool,
    zig_version: std.SemanticVersion,
    pckg_dir: std.fs.Dir,
) !void {
    inline for (.{ std.zig.Ast.Mode.zig, std.zig.Ast.Mode.zon }) |mode| {
        const text = switch (codebase) {
            .exe => if (mode == .zig) EXE_BUILD_ZIG else EXE_BUILD_ZON,
            .lib => if (mode == .zig) LIB_BUILD_ZIG else LIB_BUILD_ZON,
            .bld => if (mode == .zig) BLD_BUILD_ZIG else BLD_BUILD_ZON,
            .app => if (mode == .zig) APP_BUILD_ZIG else APP_BUILD_ZON,
        };

        var build_file = try pckg_dir.createFile(if (mode == .zig) BUILD_ZIG else BUILD_ZON, .{});
        const build_writer = build_file.writer();
        defer build_file.close();

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try build_writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'p' => try build_writer.writeAll(pckg_name),
                'u' => try build_writer.writeAll(user_hndl),
                'v' => switch (mode) {
                    .zig => try build_writer.print(
                        " .major = {d}, .minor = {d}, .patch = {d} ",
                        .{ version.major, version.minor, version.patch },
                    ),
                    .zon => try build_writer.print("{}", .{version}),
                },
                'z' => try build_writer.print("{}", .{zig_version}),
                'd' => if (add_doc) try build_writer.print(
                    \\
                    \\    // Documentation
                    \\    const docs_step = b.step("doc", "Emit documentation");
                    \\
                    \\    const docs_install = b.addInstallDirectory(.{c}
                    \\        .install_dir = .prefix,
                    \\        .install_subdir = "docs",
                    \\        .source_dir = {s}.getEmittedDocs(),
                    \\    {c});
                    \\    docs_step.dependOn(&docs_install.step);
                    \\    install_step.dependOn(docs_step);
                    \\
                , .{ '{', @tagName(codebase), '}' }),
                'c' => if (add_cov) try build_writer.writeAll(
                    \\
                    \\    // Code coverage
                    \\    const cov_step = b.step("cov", "Generate code coverage");
                    \\
                    \\    const cov_run = b.addSystemCommand(&.{ "kcov", "--clean", "--include-pattern=src/", "kcov-output/" });
                    \\    cov_run.addArtifactArg(tests);
                    \\    cov_step.dependOn(&cov_run.step);
                    \\    install_step.dependOn(cov_step);
                    \\
                ),
                else => unreachable,
            }
        }
        try build_writer.writeAll(text[idx..]);

        if (mode == .zon) {
            const build_zon = try pckg_dir.readFileAllocOptions(arena, BUILD_ZON, 512, null, @alignOf(u8), 0);

            const zig_build = try std.process.Child.run(.{
                .allocator = arena,
                .argv = &.{ "zig", "build" },
                .cwd_dir = pckg_dir,
            });
            const fingerprint_idx = std.mem.lastIndexOfScalar(u8, zig_build.stderr, 'x').?;

            var new_build_file = try pckg_dir.createFile(BUILD_ZON, .{});
            const new_build_writer = new_build_file.writer();
            defer new_build_file.close();

            try zq.process(
                arena,
                build_zon,
                ".fingerprint",
                new_build_writer,
                .{ .set_value_opt = zig_build.stderr[fingerprint_idx - 1 .. fingerprint_idx + 17] },
            );
        }
    }
}

fn createWorkflows(
    comptime ci_step: []const u8,
    runner: Runner,
    add_doc: bool,
    add_cov: bool,
    zig_version: std.SemanticVersion,
    pckg_dir: std.fs.Dir,
) !void {
    const workflows_dir_path, const all_ci_workflow, const all_cd_workflow = switch (runner) {
        .github => .{ GITHUB_WORKFLOWS, ALL_GITHUB_CI_WORKFLOW, ALL_GITHUB_CD_WORKFLOW },
        .forgejo => .{ FORGEJO_WORKFLOWS, ALL_FORGEJO_CI_WORKFLOW, ALL_FORGEJO_CD_WORKFLOW },
        .woodpecker => .{ WOODPECKER_WORKFLOWS, ALL_WOODPECKER_CI_WORKFLOW, ALL_WOODPECKER_CD_WORKFLOW },
    };

    var workflows_dir = try pckg_dir.makeOpenPath(workflows_dir_path, .{});
    defer workflows_dir.close();

    inline for (.{ CI_WORKFLOW, CD_WORKFLOW }, .{ all_ci_workflow, all_cd_workflow }) |path, text| {
        if (std.mem.startsWith(u8, path, "cd") and !add_doc) break;

        var workflow_file = try workflows_dir.createFile(path, .{});
        const workflow_writer = workflow_file.writer();
        defer workflow_file.close();

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try workflow_writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                's' => try workflow_writer.writeAll(ci_step),
                'z' => if (zig_version.build == null) {
                    try workflow_writer.print("{}", .{zig_version});
                } else {
                    try workflow_writer.writeAll("master");
                },
                'c' => if (add_cov and runner == .github) try workflow_writer.writeAll(
                    \\
                    \\      - name: Set up kcov
                    \\        run: sudo apt install kcov
                    \\
                    \\      - name: Run cov step
                    \\        run: zig build cov
                    \\
                    \\      - name: Upload coverage to Codecov
                    \\        uses: codecov/codecov-action@v5
                    \\        with:
                    \\          token: ${{ secrets.CODECOV_TOKEN }}
                    \\          directory: kcov-output/
                    \\          fail_ci_if_error: true
                    \\          verbose: true
                    \\
                ),
                else => try workflow_writer.writeAll(text[idx + i .. idx + i + 2]),
            }
        }
        try workflow_writer.writeAll(text[idx..]);
    }
}

fn createSourceFile(
    path: []const u8,
    text: []const u8,
    pckg_name: []const u8,
    src_dir: std.fs.Dir,
) !void {
    var src_file = try src_dir.createFile(path, .{});
    const src_writer = src_file.writer();
    defer src_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
        try src_writer.writeAll(text[idx .. idx + i]);
        switch (text[idx + i + 1]) {
            'p' => try src_writer.writeAll(pckg_name),
            else => unreachable,
        }
    }
    try src_writer.writeAll(text[idx..]);
}

fn createLicenseFile(
    user_name: []const u8,
    pckg_dir: std.fs.Dir,
) !void {
    var license_file = try pckg_dir.createFile(LICENSE, .{});
    const license_writer = license_file.writer();
    defer license_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, ALL_LICENSE[idx..], '$')) |i| : (idx += i + 2) {
        try license_writer.writeAll(ALL_LICENSE[idx .. idx + i]);
        switch (ALL_LICENSE[idx + i + 1]) {
            'y' => try license_writer.print("{d}", .{(try zeit.instant(.{})).time().year}),
            'n' => try license_writer.writeAll(user_name),
            else => unreachable,
        }
    }
    try license_writer.writeAll(ALL_LICENSE[idx..]);
}

fn createGitFiles(
    add_cov: bool,
    dir: std.fs.Dir,
) !void {
    inline for (.{ GITATTRIBUTES, GITIGNORE }, .{ ALL_GITATTRIBUTES, ALL_GITIGNORE }) |path, text| {
        var git_file = try dir.createFile(path, .{});
        const git_writer = git_file.writer();
        defer git_file.close();

        var idx: usize = 0;
        while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
            try git_writer.writeAll(text[idx .. idx + i]);
            switch (text[idx + i + 1]) {
                'c' => if (add_cov) try git_writer.writeAll(
                    \\
                    \\
                    \\# Kcov artifacts
                    \\kcov-output/
                ),
                else => unreachable,
            }
        }
        try git_writer.writeAll(text[idx..]);
    }
}
