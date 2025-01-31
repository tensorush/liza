const std = @import("std");
const clap = @import("clap");
const liza = @import("liza.zig");

const PARAMS = clap.parseParamsComptime(
    \\-c, --code <CBS>   Codebase type: exe, lib, prt (default: exe)
    \\-v, --ver <STR>    Codebase semantic version (default: 0.1.0)
    \\-h, --help         Display help
    \\<STR>              Repository name (default: liza)
    \\<STR>              Repository description (default: "Zig codebase initializer.")
    \\<STR>              User handle (default: tensorush)
    \\<STR>              User name (default: "Jora Troosh")
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
    const allocator = arena.allocator();
    defer arena.deinit();

    var res = try clap.parse(clap.Help, &PARAMS, PARSERS, .{ .allocator = allocator });
    defer res.deinit();

    var code_type = liza.Codebase.exe;
    var code_vrsn_str: []const u8 = "0.1.0";
    var code_vrsn = try std.SemanticVersion.parse(code_vrsn_str);

    const repo_name = res.positionals[0] orelse "liza";
    const repo_desc = res.positionals[1] orelse "Zig codebase initializer.";
    const user_hndl = res.positionals[2] orelse "tensorush";
    const user_name = res.positionals[3] orelse "Jora Troosh";

    if (res.args.code) |code| {
        code_type = code;
    }

    if (res.args.ver) |ver| {
        code_vrsn_str = ver;
        code_vrsn = try std.SemanticVersion.parse(ver);
    }

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    try liza.initialize(code_type, code_vrsn, code_vrsn_str, repo_name, repo_desc, user_hndl, user_name);
}
