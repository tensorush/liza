const std = @import("std");
const clap = @import("clap");
const liza = @import("liza.zig");

const PARAMS = clap.parseParamsComptime(
    \\-c, --cbs <CBS>   Codebase type: exe, lib, bld (default: exe)
    \\-p, --plt <PLT>   CI/CD Hosting Platform: github, forgejo (default: github)
    \\-v, --ver <STR>   Codebase semantic version (default: 0.1.0)
    \\-o, --out <STR>   Output directory path (default: ./)
    \\-h, --help        Display help
    \\<STR>             Repository name (default: liza)
    \\<STR>             Repository description (default: "Zig codebase initializer.")
    \\<STR>             User handle (default: tensorush)
    \\<STR>             User name (default: "Jora Troosh")
    \\
);

const PARSERS = .{
    .CBS = clap.parsers.enumeration(liza.Codebase),
    .PLT = clap.parsers.enumeration(liza.Platform),
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

    const codebase = cli.args.cbs orelse .exe;
    const platform = cli.args.plt orelse .github;
    const out_dir_path = cli.args.out orelse "./";
    const version_str = cli.args.ver orelse "0.1.0";
    const version = try std.SemanticVersion.parse(version_str);

    const pckg_name = cli.positionals[0] orelse "liza";
    const pckg_desc = cli.positionals[1] orelse "Zig codebase initializer.";
    const user_hndl = cli.positionals[2] orelse "tensorush";
    const user_name = cli.positionals[3] orelse "Jora Troosh";

    if (cli.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    try liza.initialize(
        gpa,
        codebase,
        platform,
        out_dir_path,
        version,
        version_str,
        pckg_name,
        pckg_desc,
        user_hndl,
        user_name,
    );
}
