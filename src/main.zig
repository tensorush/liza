const std = @import("std");
const clap = @import("clap");
const liza = @import("liza.zig");

const PARAMS = clap.parseParamsComptime(
    \\-c, --code <CBS>   Codebase type: exe, lib, prt (default: exe)
    \\-v, --ver <STR>    Codebase semantic version (default: 0.1.0)
    \\-h, --help         Display help
    \\<STR>              Repository name
    \\<STR>              Repository description
    \\<STR>              User handle
    \\<STR>              User name
    \\
);

const PARSERS = .{
    .CBS = clap.parsers.enumeration(liza.Codebase),
    .STR = clap.parsers.string,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var res = try clap.parse(clap.Help, &PARAMS, PARSERS, .{ .allocator = allocator });
    defer res.deinit();

    var code_type = liza.Codebase.exe;
    var code_vrsn_str: []const u8 = "0.1.0";
    var code_vrsn = try std.SemanticVersion.parse(code_vrsn_str);

    var repo_name: []const u8 = "liza";
    var repo_desc: []const u8 = "Zig codebase initializer.";
    var user_hndl: []const u8 = "tensorush";
    var user_name: []const u8 = "Jora Troosh";

    if (res.args.code) |code| {
        code_type = code;
    }

    if (res.args.ver) |ver| {
        code_vrsn_str = ver;
        code_vrsn = try std.SemanticVersion.parse(ver);
    }

    if (res.positionals.len > 0) {
        repo_name = res.positionals[0];
        repo_desc = res.positionals[1];
        user_hndl = res.positionals[2];
        user_name = res.positionals[3];
    }

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    try liza.initialize(code_type, code_vrsn, code_vrsn_str, repo_name, repo_desc, user_hndl, user_name);
}
