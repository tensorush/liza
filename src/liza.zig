const std = @import("std");

// Common paths.
const LICENSE_PATH = "LICENSE";
const CD_WORKFLOW_PATH = "cd.yaml";
const CI_WORKFLOW_PATH = "ci.yaml";
const GITIGNORE_PATH = ".gitignore";
const TEMPLATES_PATH = "templates/";
const GITATTRIBUTES_PATH = ".gitattributes";
const WORKFLOWS_PATH = ".github/workflows/";

// Custom paths.
const SRC_PATH = "src/";
const EXE_PATH = "exe/";
const LIB_PATH = "lib/";
const LIB_SRC_PATH = "lib.zig";
const EXE_SRC_PATH = "main.zig";
const README_PATH = "README.md";
const EXAMPLES_PATH = "examples/";
const BUILD_ZIG_PATH = "build.zig";
const BUILD_ZIG_ZON_PATH = "build.zig.zon";
const EXAMPLE1_PATH = EXAMPLES_PATH ++ "example1/";
const EXAMPLE2_PATH = EXAMPLES_PATH ++ "example2/";

// Common templates.
const LICENSE = @embedFile(TEMPLATES_PATH ++ LICENSE_PATH);
const GITIGNORE = @embedFile(TEMPLATES_PATH ++ GITIGNORE_PATH);
const GITATTRIBUTES = @embedFile(TEMPLATES_PATH ++ GITATTRIBUTES_PATH);
const CD_WORKFLOW = @embedFile(TEMPLATES_PATH ++ WORKFLOWS_PATH ++ CD_WORKFLOW_PATH);
const CI_WORKFLOW = @embedFile(TEMPLATES_PATH ++ WORKFLOWS_PATH ++ CI_WORKFLOW_PATH);

// Executable templates.
const EXE_README = @embedFile(TEMPLATES_PATH ++ EXE_PATH ++ README_PATH);
const EXE_BUILD_ZIG = @embedFile(TEMPLATES_PATH ++ EXE_PATH ++ BUILD_ZIG_PATH);
const EXE_SRC = @embedFile(TEMPLATES_PATH ++ EXE_PATH ++ SRC_PATH ++ EXE_SRC_PATH);
const EXE_BUILD_ZIG_ZON = @embedFile(TEMPLATES_PATH ++ EXE_PATH ++ BUILD_ZIG_ZON_PATH);

// Library templates.
const LIB_README = @embedFile(TEMPLATES_PATH ++ LIB_PATH ++ README_PATH);
const LIB_BUILD_ZIG = @embedFile(TEMPLATES_PATH ++ LIB_PATH ++ BUILD_ZIG_PATH);
const LIB_SRC = @embedFile(TEMPLATES_PATH ++ LIB_PATH ++ SRC_PATH ++ LIB_SRC_PATH);
const LIB_BUILD_ZIG_ZON = @embedFile(TEMPLATES_PATH ++ LIB_PATH ++ BUILD_ZIG_ZON_PATH);
const LIB_EXAMPLE1 = @embedFile(TEMPLATES_PATH ++ LIB_PATH ++ EXAMPLE1_PATH ++ EXE_SRC_PATH);
const LIB_EXAMPLE2 = @embedFile(TEMPLATES_PATH ++ LIB_PATH ++ EXAMPLE2_PATH ++ EXE_SRC_PATH);

pub fn initialize(
    codebase_title: []const u8,
    codebase_desc: []const u8,
    user_handle: []const u8,
    user_name: []const u8,
    is_lib: bool,
) !void {
    var codebase_dir = blk: {
        const cur_dir = std.fs.cwd();
        _ = cur_dir.access(codebase_title, .{}) catch break :blk try cur_dir.makeOpenPath(codebase_title, .{});
        @panic("Codebase directory already exists!");
    };
    defer codebase_dir.close();

    var workflows_dir = try codebase_dir.makeOpenPath(WORKFLOWS_PATH, .{});
    defer workflows_dir.close();

    var src_dir = try codebase_dir.makeOpenPath(SRC_PATH, .{});
    defer src_dir.close();

    try createLicense(user_name, codebase_dir);
    try createPlain(GITIGNORE_PATH, GITIGNORE, codebase_dir);
    try createPlain(CD_WORKFLOW_PATH, CD_WORKFLOW, workflows_dir);
    try createPlain(GITATTRIBUTES_PATH, GITATTRIBUTES, codebase_dir);

    if (is_lib) {
        var example1_dir = try codebase_dir.makeOpenPath(EXAMPLE1_PATH, .{});
        defer example1_dir.close();

        var example2_dir = try codebase_dir.makeOpenPath(EXAMPLE2_PATH, .{});
        defer example2_dir.close();

        try createPlain(LIB_SRC_PATH, LIB_SRC, src_dir);
        try createPlain(EXE_SRC_PATH, LIB_EXAMPLE1, example1_dir);
        try createPlain(EXE_SRC_PATH, LIB_EXAMPLE2, example2_dir);
        try createCi("example", workflows_dir);
        try createBuild(BUILD_ZIG_PATH, LIB_BUILD_ZIG, codebase_title, codebase_dir);
        try createBuild(BUILD_ZIG_ZON_PATH, LIB_BUILD_ZIG_ZON, codebase_title, codebase_dir);
        try createReadme(LIB_README, codebase_title, codebase_desc, user_handle, codebase_dir);
    } else {
        try createPlain(EXE_SRC_PATH, EXE_SRC, src_dir);
        try createCi("exe", workflows_dir);
        try createBuild(BUILD_ZIG_PATH, EXE_BUILD_ZIG, codebase_title, codebase_dir);
        try createBuild(BUILD_ZIG_ZON_PATH, EXE_BUILD_ZIG_ZON, codebase_title, codebase_dir);
        try createReadme(EXE_README, codebase_title, codebase_desc, user_handle, codebase_dir);
    }
}

fn createReadme(
    comptime README: []const u8,
    codebase_title: []const u8,
    codebase_desc: []const u8,
    user_handle: []const u8,
    codebase_dir: std.fs.Dir,
) !void {
    var readme_file = try codebase_dir.createFile(README_PATH, .{});
    defer readme_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, README[idx..], '?')) |i| : (idx += i + 2) {
        try readme_file.writeAll(README[idx .. idx + i]);
        switch (README[idx + i + 1]) {
            't' => try readme_file.writeAll(codebase_title),
            'd' => try readme_file.writeAll(codebase_desc),
            'h' => try readme_file.writeAll(user_handle),
            else => try readme_file.writeAll(README[idx + i .. idx + i + 2]),
        }
    }
    try readme_file.writeAll(README[idx..]);
}

fn createBuild(
    comptime PATH: []const u8,
    comptime TEXT: []const u8,
    codebase_title: []const u8,
    codebase_dir: std.fs.Dir,
) !void {
    var build_file = try codebase_dir.createFile(PATH, .{});
    defer build_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, TEXT[idx..], '?')) |i| : (idx += i + 1) {
        try build_file.writeAll(TEXT[idx .. idx + i]);
        try build_file.writeAll(codebase_title);
    }
    try build_file.writeAll(TEXT[idx..]);
}

fn createCi(
    comptime STEP: []const u8,
    workflows_dir: std.fs.Dir,
) !void {
    var ci_file = try workflows_dir.createFile(CI_WORKFLOW_PATH, .{});
    defer ci_file.close();

    var idx: usize = 0;
    while (std.mem.indexOfScalar(u8, CI_WORKFLOW[idx..], '?')) |i| : (idx += i + 1) {
        try ci_file.writeAll(CI_WORKFLOW[idx .. idx + i]);
        try ci_file.writeAll(STEP);
    }
    try ci_file.writeAll(CI_WORKFLOW[idx..]);
}

fn createLicense(
    user_name: []const u8,
    codebase_dir: std.fs.Dir,
) !void {
    var license_file = try codebase_dir.createFile(LICENSE_PATH, .{});
    defer license_file.close();

    const idx = std.mem.indexOfScalar(u8, LICENSE, '?').?;
    try license_file.writeAll(LICENSE[0..idx]);
    try license_file.writeAll(user_name);
    try license_file.writeAll(LICENSE[idx + 1 ..]);
}

fn createPlain(
    comptime PATH: []const u8,
    comptime TEXT: []const u8,
    dir: std.fs.Dir,
) !void {
    var plain_file = try dir.createFile(PATH, .{});
    defer plain_file.close();

    try plain_file.writeAll(TEXT);
}
