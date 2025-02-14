const std = @import("std");
const zeit = @import("zeit");

// Common paths.
const LICENSE = "LICENSE";
const CD_WORKFLOW = "cd.yaml";
const CI_WORKFLOW = "ci.yaml";
const TEMPLATES = "templates/";
const GITIGNORE = ".gitignore";
const GITATTRIBUTES = ".gitattributes";
const GITHUB_WORKFLOWS = ".github/workflows/";
const FORGEJO_WORKFLOWS = ".forgejo/workflows/";

// Custom paths.
const SRC = "src/";
const EXE = "exe/";
const LIB = "lib/";
const BLD = "bld/";
const README = "README.md";
const EXE_CORE = "$p.zig";
const EXE_ROOT = "main.zig";
const LIB_ROOT = "root.zig";
const EXAMPLES = "examples/";
const BUILD_ZIG = "build.zig";
const BUILD_ZON = "build.zig.zon";
const EXAMPLE1 = EXAMPLES ++ "example1/";
const EXAMPLE2 = EXAMPLES ++ "example2/";

// Common templates.
const ALL_LICENSE = @embedFile(TEMPLATES ++ LICENSE);
const ALL_GITIGNORE = @embedFile(TEMPLATES ++ GITIGNORE);
const ALL_GITATTRIBUTES = @embedFile(TEMPLATES ++ GITATTRIBUTES);
const ALL_GITHUB_CI_WORKFLOW = @embedFile(TEMPLATES ++ GITHUB_WORKFLOWS ++ CI_WORKFLOW);
const ALL_GITHUB_CD_WORKFLOW = @embedFile(TEMPLATES ++ GITHUB_WORKFLOWS ++ CD_WORKFLOW);
const ALL_FORGEJO_CI_WORKFLOW = @embedFile(TEMPLATES ++ FORGEJO_WORKFLOWS ++ CI_WORKFLOW);
const ALL_FORGEJO_CD_WORKFLOW = @embedFile(TEMPLATES ++ FORGEJO_WORKFLOWS ++ CD_WORKFLOW);

// Executable templates.
const EXE_CI_STEP = "exe";
const EXE_README = @embedFile(TEMPLATES ++ EXE ++ README);
const EXE_BUILD_ZIG = @embedFile(TEMPLATES ++ EXE ++ BUILD_ZIG);
const EXE_BUILD_ZON = @embedFile(TEMPLATES ++ EXE ++ BUILD_ZON);
const EXE_CORE_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_CORE);
const EXE_ROOT_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_ROOT);

// Library templates.
const LIB_CI_STEP = "example";
const LIB_README = @embedFile(TEMPLATES ++ LIB ++ README);
const LIB_BUILD_ZIG = @embedFile(TEMPLATES ++ LIB ++ BUILD_ZIG);
const LIB_BUILD_ZON = @embedFile(TEMPLATES ++ LIB ++ BUILD_ZON);
const LIB_ROOT_TEXT = @embedFile(TEMPLATES ++ LIB ++ SRC ++ LIB_ROOT);
const LIB_EXAMPLE1 = @embedFile(TEMPLATES ++ LIB ++ EXAMPLE1 ++ EXE_ROOT);
const LIB_EXAMPLE2 = @embedFile(TEMPLATES ++ LIB ++ EXAMPLE2 ++ EXE_ROOT);

// Build templates.
const BLD_CI_STEP = "lib";
const BLD_README = @embedFile(TEMPLATES ++ BLD ++ README);
const BLD_BUILD_ZIG = @embedFile(TEMPLATES ++ BLD ++ BUILD_ZIG);
const BLD_BUILD_ZON = @embedFile(TEMPLATES ++ BLD ++ BUILD_ZON);

pub const Codebase = enum {
    exe,
    lib,
    bld,
};

pub const Runner = enum {
    github,
    forgejo,
};

pub fn initialize(
    gpa: std.mem.Allocator,
    codebase: Codebase,
    runner: Runner,
    out_dir_path: []const u8,
    version_str: []const u8,
    pckg_name: []const u8,
    pckg_desc: []const u8,
    user_hndl: []const u8,
    user_name: []const u8,
) !void {
    var pckg_dir = blk: {
        const out_dir = try std.fs.cwd().openDir(out_dir_path, .{});
        _ = out_dir.access(pckg_name, .{}) catch break :blk try out_dir.makeOpenPath(pckg_name, .{});
        @panic("Directory already exists!");
    };
    defer pckg_dir.close();

    var src_dir = try pckg_dir.makeOpenPath(SRC, .{});
    defer src_dir.close();

    try createLicense(user_name, pckg_dir);
    try createPlain(GITIGNORE, ALL_GITIGNORE, pckg_dir);
    try createPlain(GITATTRIBUTES, ALL_GITATTRIBUTES, pckg_dir);

    const version = try std.SemanticVersion.parse(version_str);

    switch (codebase) {
        .exe => {
            const exe_core = try std.mem.concat(gpa, u8, &.{ pckg_name, ".zig" });
            defer gpa.free(exe_core);

            try createSource(exe_core, EXE_CORE_TEXT, pckg_name, src_dir);
            try createSource(EXE_ROOT, EXE_ROOT_TEXT, pckg_name, src_dir);
            try createWorkflows(EXE_CI_STEP, codebase, runner, pckg_dir);
            try createBuild(.zig, .exe, pckg_name, user_hndl, version, pckg_dir);
            try createBuild(.zon, .exe, pckg_name, user_hndl, version_str, pckg_dir);
            try createReadme(EXE_README, runner, pckg_name, pckg_desc, user_hndl, pckg_dir);
        },
        .lib => {
            var example1_dir = try pckg_dir.makeOpenPath(EXAMPLE1, .{});
            defer example1_dir.close();

            var example2_dir = try pckg_dir.makeOpenPath(EXAMPLE2, .{});
            defer example2_dir.close();

            try createSource(LIB_ROOT, LIB_ROOT_TEXT, pckg_name, src_dir);
            try createWorkflows(LIB_CI_STEP, codebase, runner, pckg_dir);
            try createSource(EXE_ROOT, LIB_EXAMPLE1, pckg_name, example1_dir);
            try createSource(EXE_ROOT, LIB_EXAMPLE2, pckg_name, example2_dir);
            try createBuild(.zig, .lib, pckg_name, user_hndl, version, pckg_dir);
            try createBuild(.zon, .lib, pckg_name, user_hndl, version_str, pckg_dir);
            try createReadme(LIB_README, runner, pckg_name, pckg_desc, user_hndl, pckg_dir);
        },
        .bld => {
            try createWorkflows(BLD_CI_STEP, codebase, runner, pckg_dir);
            try createBuild(.zig, .bld, pckg_name, user_hndl, version, pckg_dir);
            try createBuild(.zon, .bld, pckg_name, user_hndl, version_str, pckg_dir);
            try createReadme(BLD_README, runner, pckg_name, pckg_desc, user_hndl, pckg_dir);
        },
    }
}

fn createReadme(
    comptime text: []const u8,
    runner: Runner,
    pckg_name: []const u8,
    pckg_desc: []const u8,
    user_hndl: []const u8,
    pckg_dir: std.fs.Dir,
) !void {
    var readme_file = try pckg_dir.createFile(README, .{});
    defer readme_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfAny(u8, text[idx..], "$[")) |i| : (idx += i + 1) {
        try readme_file.writeAll(text[idx .. idx + i]);
        switch (text[idx + i]) {
            '$' => {
                switch (text[idx + i + 1]) {
                    'p' => try readme_file.writeAll(pckg_name),
                    'd' => try readme_file.writeAll(pckg_desc),
                    'u' => try readme_file.writeAll(user_hndl),
                    else => try readme_file.writeAll(text[idx + i .. idx + i + 2]),
                }
                idx += 1;
            },
            '[' => switch (runner) {
                .github => try readme_file.writeAll("["),
                .forgejo => idx += std.mem.indexOfScalar(u8, text[idx + i ..], '\n').?,
            },
            else => unreachable,
        }
    }
    try readme_file.writeAll(text[idx..]);
}

fn createBuild(
    comptime mode: std.zig.Ast.Mode,
    comptime codebase: Codebase,
    pckg_name: []const u8,
    user_hndl: []const u8,
    version: anytype,
    pckg_dir: std.fs.Dir,
) !void {
    const text = switch (codebase) {
        .exe => if (mode == .zig) EXE_BUILD_ZIG else EXE_BUILD_ZON,
        .lib => if (mode == .zig) LIB_BUILD_ZIG else LIB_BUILD_ZON,
        .bld => if (mode == .zig) BLD_BUILD_ZIG else BLD_BUILD_ZON,
    };
    var build_file = try pckg_dir.createFile(if (mode == .zig) BUILD_ZIG else BUILD_ZON, .{});
    const build_writer = build_file.writer();
    defer build_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
        try build_file.writeAll(text[idx .. idx + i]);
        switch (text[idx + i + 1]) {
            'p' => try build_writer.writeAll(pckg_name),
            'v' => switch (mode) {
                .zig => try build_writer.print(
                    " .major = {d}, .minor = {d}, .patch = {d} ",
                    .{ version.major, version.minor, version.patch },
                ),
                .zon => try build_writer.writeAll(version),
            },
            'u' => try build_writer.writeAll(user_hndl),
            else => unreachable,
        }
    }
    try build_file.writeAll(text[idx..]);
}

fn createWorkflows(
    comptime step: []const u8,
    codebase: Codebase,
    runner: Runner,
    pckg_dir: std.fs.Dir,
) !void {
    const workflows, const all_ci_workflow, const all_cd_workflow = switch (runner) {
        .forgejo => .{ FORGEJO_WORKFLOWS, ALL_FORGEJO_CI_WORKFLOW, ALL_FORGEJO_CD_WORKFLOW },
        .github => .{ GITHUB_WORKFLOWS, ALL_GITHUB_CI_WORKFLOW, ALL_GITHUB_CD_WORKFLOW },
    };

    var workflows_dir = try pckg_dir.makeOpenPath(workflows, .{});
    defer workflows_dir.close();

    if (codebase != .bld) {
        try createPlain(CD_WORKFLOW, all_cd_workflow, workflows_dir);
    }

    var ci_file = try workflows_dir.createFile(CI_WORKFLOW, .{});
    defer ci_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, all_ci_workflow[idx..], '$')) |i| : (idx += i + 2) {
        try ci_file.writeAll(all_ci_workflow[idx .. idx + i]);
        switch (all_ci_workflow[idx + i + 1]) {
            's' => try ci_file.writeAll(step),
            else => {},
        }
    }
    try ci_file.writeAll(all_ci_workflow[idx..]);
}

fn createSource(
    path: []const u8,
    comptime text: []const u8,
    pckg_name: []const u8,
    src_dir: std.fs.Dir,
) !void {
    var src_file = try src_dir.createFile(path, .{});
    defer src_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '$')) |i| : (idx += i + 2) {
        try src_file.writeAll(text[idx .. idx + i]);
        switch (text[idx + i + 1]) {
            'p' => try src_file.writeAll(pckg_name),
            else => unreachable,
        }
    }
    try src_file.writeAll(text[idx..]);
}

fn createLicense(
    user_name: []const u8,
    pckg_dir: std.fs.Dir,
) !void {
    var license_file = try pckg_dir.createFile(LICENSE, .{});
    defer license_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, ALL_LICENSE[idx..], '$')) |i| : (idx += i + 2) {
        try license_file.writeAll(ALL_LICENSE[idx .. idx + i]);
        switch (ALL_LICENSE[idx + i + 1]) {
            'y' => try license_file.writer().print("{d}", .{(try zeit.instant(.{})).time().year}),
            'n' => try license_file.writeAll(user_name),
            else => unreachable,
        }
    }
    try license_file.writeAll(ALL_LICENSE[idx..]);
}

fn createPlain(
    comptime path: []const u8,
    text: []const u8,
    dir: std.fs.Dir,
) !void {
    var plain_file = try dir.createFile(path, .{});
    defer plain_file.close();

    try plain_file.writeAll(text);
}
