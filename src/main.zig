const std = @import("std");

const argzon = @import("argzon");

const liza = @import("liza.zig");

const CLI = @import("cli.zon");

const PCKG_NAME_PREFIX = "zig-";

pub fn main() !void {
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) @panic("Memory leaked!");

    var arena_state: std.heap.ArenaAllocator = .init(gpa);
    const arena = arena_state.allocator();
    defer arena_state.deinit();

    var stderr_buf: [argzon.MAX_BUF_SIZE]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);

    var arg_str_iter = try std.process.argsWithAllocator(gpa);
    defer arg_str_iter.deinit();

    const Args = argzon.Args(CLI, .{ .enums = &.{ liza.Codebase, liza.Runner } });
    const args: Args = try .parse(arena, &arg_str_iter, &stderr_writer.interface, .{ .is_gpa = false });

    const codebase = args.options.cbs;
    const runner = args.options.rnr;
    const version: std.SemanticVersion = try .parse(args.options.ver);
    const out_dir_path = args.options.out;

    const add_doc = args.flags.@"add-doc";
    const add_cov = args.flags.@"add-cov";
    const add_check = args.flags.@"add-check";
    const fetch_deps = args.flags.@"fetch-deps";

    const pckg_name_with_prefix_opt = if (codebase == .lib and std.mem.startsWith(u8, args.positionals.PCKG_NAME, PCKG_NAME_PREFIX))
        args.positionals.PCKG_NAME
    else
        null;
    const pckg_name = if (pckg_name_with_prefix_opt) |pckg_name_with_prefix|
        pckg_name_with_prefix[PCKG_NAME_PREFIX.len..]
    else
        args.positionals.PCKG_NAME;

    const pckg_desc = args.positionals.PCKG_DESC;
    const user_hndl = args.positionals.USER_HNDL;
    const user_name = args.positionals.USER_NAME;

    if (!std.zig.isValidId(pckg_name)) {
        @panic("Package name must be a valid Zig identifier, only library's name can be prefixed with \"" ++ PCKG_NAME_PREFIX ++ "\"!");
    }

    const zig_version_run = try std.process.Child.run(.{ .allocator = arena, .argv = &.{ "zig", "version" } });
    const zig_version: std.SemanticVersion = try .parse(std.mem.trimRight(u8, zig_version_run.stdout, "\n"));

    try liza.initialize(
        arena,
        pckg_name_with_prefix_opt,
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
        add_check,
        fetch_deps,
        zig_version,
    );
}
