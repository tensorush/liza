//! Root source file that exposes the executable's main function.

const std = @import("std");
const clap = @import("clap");

const $p = @import("$p.zig");

const PARAMS = clap.parseParamsComptime(
    \\-o, --opt <u8>   Optional argument (default: 3)
    \\-h, --help       Display help
    \\<str>            Positional argument
    \\
);

pub fn main() !void {
    // Set up general-purpose allocator
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    // Set up CLI argument parsing
    var cli = try clap.parse(clap.Help, &PARAMS, clap.parsers.default, .{ .allocator = gpa });
    defer cli.deinit();

    // Handle help flag first
    if (cli.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    // Handle positional arguments
    const pos_arg = cli.positionals[0] orelse @panic("Provide a positional argument!");

    // Handle optional arguments
    const opt_arg = cli.args.opt orelse 3;

    // Set up buffered standard output writer
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    // Run core logic
    try $p.run(pos_arg, opt_arg, writer);

    // Flush standard output
    try buf_writer.flush();
}

test {
    std.testing.refAllDecls($p);
}
