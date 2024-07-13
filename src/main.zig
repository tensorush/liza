const std = @import("std");
const clap = @import("clap");
const liza = @import("liza.zig");

const PARAMS = clap.parseParamsComptime(
    \\-l, --lib    Enable library initialization.
    \\-h, --help   Display help menu.
    \\<str>        Codebase name.
    \\<str>        Codebase description.
    \\<str>        User handle.
    \\<str>        Full user name.
    \\
);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();

    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &PARAMS, clap.parsers.default, .{ .allocator = allocator, .diagnostic = &diag }) catch |err| {
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    var codebase_name: []const u8 = "liza";
    var codebase_desc: []const u8 = "Zig codebase initializer.";
    var user_handle: []const u8 = "tensorush";
    var user_name: []const u8 = "Jora Troosh";
    var is_lib = false;

    if (res.positionals.len > 0) {
        codebase_name = res.positionals[0];
        codebase_desc = res.positionals[1];
        user_handle = res.positionals[2];
        user_name = res.positionals[3];
    }

    if (res.args.lib != 0) {
        is_lib = true;
    }

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    try liza.initialize(codebase_name, codebase_desc, user_handle, user_name, is_lib);
}
