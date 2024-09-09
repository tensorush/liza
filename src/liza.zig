const std = @import("std");

// Common paths.
const LICENSE = "LICENSE";
const CD_WORKFLOW = "cd.yaml";
const CI_WORKFLOW = "ci.yaml";
const TEMPLATES = "templates/";
const GITIGNORE = ".gitignore";
const WORKFLOWS = ".github/workflows/";
const GITATTRIBUTES = ".gitattributes";

// Custom paths.
const SRC = "src/";
const EXE = "exe/";
const LIB = "lib/";
const PRT = "prt/";
const README = "README.md";
const LIB_ROOT = "lib.zig";
const EXE_ROOT = "main.zig";
const EXAMPLES = "examples/";
const BUILD_ZIG = "build.zig";
const BUILD_ZON = "build.zig.zon";
const EXAMPLE1 = EXAMPLES ++ "example1/";
const EXAMPLE2 = EXAMPLES ++ "example2/";

// Common templates.
const ALL_LICENSE = @embedFile(TEMPLATES ++ LICENSE);
const ALL_GITIGNORE = @embedFile(TEMPLATES ++ GITIGNORE);
const ALL_GITATTRIBUTES = @embedFile(TEMPLATES ++ GITATTRIBUTES);
const ALL_CD_WORKFLOW = @embedFile(TEMPLATES ++ WORKFLOWS ++ CD_WORKFLOW);
const ALL_CI_WORKFLOW = @embedFile(TEMPLATES ++ WORKFLOWS ++ CI_WORKFLOW);

// Executable templates.
const EXE_CI_STEP = "exe";
const EXE_README = @embedFile(TEMPLATES ++ EXE ++ README);
const EXE_BUILD_ZIG = @embedFile(TEMPLATES ++ EXE ++ BUILD_ZIG);
const EXE_BUILD_ZON = @embedFile(TEMPLATES ++ EXE ++ BUILD_ZON);
const EXE_TEXT = @embedFile(TEMPLATES ++ EXE ++ SRC ++ EXE_ROOT);

// Library templates.
const LIB_CI_STEP = "example";
const LIB_README = @embedFile(TEMPLATES ++ LIB ++ README);
const LIB_BUILD_ZIG = @embedFile(TEMPLATES ++ LIB ++ BUILD_ZIG);
const LIB_BUILD_ZON = @embedFile(TEMPLATES ++ LIB ++ BUILD_ZON);
const LIB_TEXT = @embedFile(TEMPLATES ++ LIB ++ SRC ++ LIB_ROOT);
const LIB_EXAMPLE1 = @embedFile(TEMPLATES ++ LIB ++ EXAMPLE1 ++ EXE_ROOT);
const LIB_EXAMPLE2 = @embedFile(TEMPLATES ++ LIB ++ EXAMPLE2 ++ EXE_ROOT);

// Port templates.
const PRT_CI_STEP = "lib";
const PRT_README = @embedFile(TEMPLATES ++ PRT ++ README);
const PRT_BUILD_ZIG = @embedFile(TEMPLATES ++ PRT ++ BUILD_ZIG);
const PRT_BUILD_ZON = @embedFile(TEMPLATES ++ PRT ++ BUILD_ZON);
const PRT_TEXT = @embedFile(TEMPLATES ++ PRT ++ SRC ++ LIB_ROOT);

pub const Codebase = enum {
    exe,
    lib,
    prt,
};

pub fn initialize(
    code_type: Codebase,
    code_vrsn: std.SemanticVersion,
    code_vrsn_str: []const u8,
    repo_name: []const u8,
    repo_desc: []const u8,
    user_hndl: []const u8,
    user_name: []const u8,
) !void {
    var repo_dir = blk: {
        const cur_dir = std.fs.cwd();
        _ = cur_dir.access(repo_name, .{}) catch break :blk try cur_dir.makeOpenPath(repo_name, .{});
        @panic("Directory already exists!");
    };
    defer repo_dir.close();

    var workflows_dir = try repo_dir.makeOpenPath(WORKFLOWS, .{});
    defer workflows_dir.close();

    var src_dir = try repo_dir.makeOpenPath(SRC, .{});
    defer src_dir.close();

    try createLicense(user_name, repo_dir);
    try createPlain(GITIGNORE, ALL_GITIGNORE, repo_dir);
    try createPlain(GITATTRIBUTES, ALL_GITATTRIBUTES, repo_dir);
    if (code_type != .prt) {
        try createPlain(CD_WORKFLOW, ALL_CD_WORKFLOW, workflows_dir);
    }

    switch (code_type) {
        .exe => {
            try createCi(EXE_CI_STEP, workflows_dir);
            try createPlain(EXE_ROOT, EXE_TEXT, src_dir);
            try createBuild(.zig, .exe, repo_name, user_hndl, code_vrsn, repo_dir);
            try createBuild(.zon, .exe, repo_name, user_hndl, code_vrsn_str, repo_dir);
            try createReadme(EXE_README, repo_name, repo_desc, user_hndl, repo_dir);
        },
        .lib => {
            var example1_dir = try repo_dir.makeOpenPath(EXAMPLE1, .{});
            defer example1_dir.close();

            var example2_dir = try repo_dir.makeOpenPath(EXAMPLE2, .{});
            defer example2_dir.close();

            try createCi(LIB_CI_STEP, workflows_dir);
            try createPlain(LIB_ROOT, LIB_TEXT, src_dir);
            try createPlain(EXE_ROOT, LIB_EXAMPLE1, example1_dir);
            try createPlain(EXE_ROOT, LIB_EXAMPLE2, example2_dir);
            try createBuild(.zig, .lib, repo_name, user_hndl, code_vrsn, repo_dir);
            try createBuild(.zon, .lib, repo_name, user_hndl, code_vrsn_str, repo_dir);
            try createReadme(LIB_README, repo_name, repo_desc, user_hndl, repo_dir);
        },
        .prt => {
            try createCi(PRT_CI_STEP, workflows_dir);
            try createPlain(LIB_ROOT, PRT_TEXT, src_dir);
            try createBuild(.zig, .prt, repo_name, user_hndl, code_vrsn, repo_dir);
            try createBuild(.zon, .prt, repo_name, user_hndl, code_vrsn_str, repo_dir);
            try createReadme(PRT_README, repo_name, repo_desc, user_hndl, repo_dir);
        },
    }
}

fn createReadme(
    comptime text: []const u8,
    repo_name: []const u8,
    repo_desc: []const u8,
    user_hndl: []const u8,
    repo_dir: std.fs.Dir,
) !void {
    var readme_file = try repo_dir.createFile(README, .{});
    defer readme_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '?')) |i| : (idx += i + 2) {
        try readme_file.writeAll(text[idx .. idx + i]);
        switch (text[idx + i + 1]) {
            'r' => try readme_file.writeAll(repo_name),
            'd' => try readme_file.writeAll(repo_desc),
            'u' => try readme_file.writeAll(user_hndl),
            else => try readme_file.writeAll(text[idx + i .. idx + i + 2]),
        }
    }
    try readme_file.writeAll(text[idx..]);
}

fn createBuild(
    comptime mode: std.zig.Ast.Mode,
    comptime codebase: Codebase,
    repo_name: []const u8,
    user_hndl: []const u8,
    version: anytype,
    repo_dir: std.fs.Dir,
) !void {
    const text = switch (codebase) {
        .exe => if (mode == .zig) EXE_BUILD_ZIG else EXE_BUILD_ZON,
        .lib => if (mode == .zig) LIB_BUILD_ZIG else LIB_BUILD_ZON,
        .prt => if (mode == .zig) PRT_BUILD_ZIG else PRT_BUILD_ZON,
    };
    var build_file = try repo_dir.createFile(if (mode == .zig) BUILD_ZIG else BUILD_ZON, .{});
    const build_writer = build_file.writer();
    defer build_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, text[idx..], '?')) |i| : (idx += i + 2) {
        try build_file.writeAll(text[idx .. idx + i]);
        switch (text[idx + i + 1]) {
            'r' => try build_writer.writeAll(repo_name),
            'v' => switch (mode) {
                .zig => try build_writer.print(
                    " .major = {}, .minor = {}, .patch = {} ",
                    .{ version.major, version.minor, version.patch },
                ),
                .zon => try build_writer.writeAll(version),
            },
            'u' => try build_writer.writeAll(user_hndl),
            else => try build_writer.writeAll(text[idx + i .. idx + i + 2]),
        }
    }
    try build_file.writeAll(text[idx..]);
}

fn createCi(
    comptime step: []const u8,
    workflows_dir: std.fs.Dir,
) !void {
    var ci_file = try workflows_dir.createFile(CI_WORKFLOW, .{});
    defer ci_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, ALL_CI_WORKFLOW[idx..], '?')) |i| : (idx += i + 1) {
        try ci_file.writeAll(ALL_CI_WORKFLOW[idx .. idx + i]);
        try ci_file.writeAll(step);
    }
    try ci_file.writeAll(ALL_CI_WORKFLOW[idx..]);
}

fn createLicense(
    user_name: []const u8,
    repo_dir: std.fs.Dir,
) !void {
    var license_file = try repo_dir.createFile(LICENSE, .{});
    defer license_file.close();

    const idx = std.mem.indexOfScalar(u8, ALL_LICENSE, '?').?;
    try license_file.writeAll(ALL_LICENSE[0..idx]);
    try license_file.writeAll(user_name);
    try license_file.writeAll(ALL_LICENSE[idx + 1 ..]);
}

fn createPlain(
    comptime path: []const u8,
    comptime text: []const u8,
    dir: std.fs.Dir,
) !void {
    var plain_file = try dir.createFile(path, .{});
    defer plain_file.close();

    try plain_file.writeAll(text);
}
