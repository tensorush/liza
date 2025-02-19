const std = @import("std");
const clap = @import("clap");

const liza = @import("liza.zig");

const PARAMS = clap.parseParamsComptime(
    \\-p, --pckg <STR>   Package name (default: liza)
    \\-d, --desc <STR>   Package description (default: "Zig codebase initializer.")
    \\-u, --user <STR>   User handle (default: tensorush)
    \\-n, --name <STR>   User name (default: "Jora Troosh")
    \\-c, --cbs  <CBS>   Codebase type: exe, lib, bld, app (default: exe)
    \\-r, --rnr  <RNR>   CI/CD runner type: github, forgejo (default: github)
    \\-v, --ver  <STR>   Codebase semantic version triple (default: 0.1.0)
    \\-o, --out  <STR>   Output directory path (default: ./)
    \\-h, --help         Display help
    \\
);

const PARSERS = .{
    .CBS = clap.parsers.enumeration(liza.Codebase),
    .RNR = clap.parsers.enumeration(liza.Runner),
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

    if (cli.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    const pckg_name = cli.args.pckg orelse "liza";
    const pckg_desc = cli.args.desc orelse "Zig codebase initializer.";
    const user_hndl = cli.args.user orelse "tensorush";
    const user_name = cli.args.name orelse "Jora Troosh";
    const codebase = cli.args.cbs orelse .exe;
    const runner = cli.args.rnr orelse .github;
    const version_str = cli.args.ver orelse "0.1.0";
    const out_dir_path = cli.args.out orelse "./";

    try liza.initialize(
        gpa,
        codebase,
        runner,
        out_dir_path,
        version_str,
        pckg_name,
        pckg_desc,
        user_hndl,
        user_name,
    );
}
