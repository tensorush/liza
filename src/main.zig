const std = @import("std");

const clap = @import("clap");

const liza = @import("liza.zig");

const PARAMS = clap.parseParamsComptime(
    \\-c, --cbs  <CBS>   Codebase type: exe, lib, bld, app (default: exe)
    \\-r, --rnr  <RNR>   CI/CD runner type: github, forgejo, woodpecker (default: github)
    \\-v, --ver  <STR>   Codebase semantic version triple (default: 0.1.0)
    \\-o, --out  <STR>   Output directory path (default: ./)
    \\--add-doc          Add documentation to exe or lib (add doc step, add CD workflow)
    \\--add-cov          Add code coverage to exe or lib (add cov step, edit CI workflow, edit .gitignore)
    \\-h, --help         Display help
    \\<STR>              Package name (e.g. liza)
    \\<STR>              Package description (e.g. "Zig codebase initializer.")
    \\<STR>              User handle (e.g. tensorush)
    \\<STR>              User name (e.g. "Jora Troosh")
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

    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();
    defer arena_state.deinit();

    var cli = try clap.parse(clap.Help, &PARAMS, PARSERS, .{ .allocator = gpa });
    defer cli.deinit();

    if (cli.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    const pckg_name = cli.positionals[0] orelse @panic("Provide a package name!");
    const pckg_desc = cli.positionals[1] orelse @panic("Provide a package description!");
    const user_hndl = cli.positionals[2] orelse @panic("Provide a user handle!");
    const user_name = cli.positionals[3] orelse @panic("Provide a user name!");

    const codebase = cli.args.cbs orelse .exe;
    const runner = cli.args.rnr orelse .github;
    const version = try std.SemanticVersion.parse(cli.args.ver orelse "0.1.0");
    const out_dir_path = cli.args.out orelse "./";
    const add_doc = if (cli.args.@"add-doc" != 0) true else false;
    const add_cov = if (cli.args.@"add-cov" != 0) true else false;

    switch (codebase) {
        .exe, .lib => {},
        .bld, .app => if (add_doc or add_cov) {
            @panic("Options add-doc and add-cov are unavailable for bld and app codebases!");
        },
    }

    const zig_version_run = try std.process.Child.run(.{ .allocator = arena, .argv = &.{ "zig", "version" } });
    const zig_version = try std.SemanticVersion.parse(std.mem.trimRight(u8, zig_version_run.stdout, "\n"));

    try liza.initialize(
        arena,
        pckg_name,
        pckg_desc,
        user_hndl,
        user_name,
        codebase,
        runner,
        version,
        out_dir_path,
        add_doc,
        add_cov,
        zig_version,
    );
}
