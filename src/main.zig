const std = @import("std");
const clap = @import("clap");
const liza = @import("liza.zig");

const PARAMS = clap.parseParamsComptime(
    \\-c, --code <CBS>   Codebase type: exe, lib, prt (default: exe)
    \\-v, --ver <STR>    Codebase semantic version (default: 0.1.0)
    \\-o, --out <STR>    Output directory path (default: ./)
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
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    var cli = try clap.parse(clap.Help, &PARAMS, PARSERS, .{ .allocator = gpa });
    defer cli.deinit();

    const code_type = cli.args.code orelse .exe;
    const out_dir_str = cli.args.out orelse "./";
    const code_vrsn_str = cli.args.ver orelse "0.1.0";
    const code_vrsn = try std.SemanticVersion.parse(code_vrsn_str);

    const repo_name = cli.positionals[0] orelse "liza";
    const repo_desc = cli.positionals[1] orelse "Zig codebase initializer.";
    const user_hndl = cli.positionals[2] orelse "tensorush";
    const user_name = cli.positionals[3] orelse "Jora Troosh";

    if (cli.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    try liza.initialize(code_type, out_dir_str, code_vrsn, code_vrsn_str, repo_name, repo_desc, user_hndl, user_name);
}
