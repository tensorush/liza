//! Root source file that exposes the executable's main function.

const std = @import("std");
const clap = @import("clap");

const $p = @import("$p.zig");

const PARAMS = clap.parseParamsComptime(
    \\-h, --help   Display help
    \\
);

pub fn main() !void {
    // Set up general-purpose allocator.
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    // Set up CLI argument parsing.
    var cli = try clap.parse(clap.Help, &PARAMS, clap.parsers.default, .{ .allocator = gpa });
    defer cli.deinit();

    // Parse help argument.
    if (cli.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    // Set up buffered standard output writer.
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    // Run core logic.
    try $p.runCoreLogic(writer);

    // Flushing standard output.
    try buf_writer.flush();
}
