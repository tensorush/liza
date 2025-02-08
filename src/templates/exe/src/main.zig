//! Root source file that exposes the executable's main function.

const std = @import("std");
const clap = @import("clap");

const PARAMS = clap.parseParamsComptime(
    \\-h, --help   Display help
    \\
);

pub fn main() !void {
    // Set up general-purpose allocator.
    var gpa_state: std.heap.GeneralPurposeAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    // Set up arena allocator.
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();
    defer arena_state.deinit();

    // Set up CLI argument parsing.
    var cli = try clap.parse(clap.Help, &PARAMS, clap.parsers.default, .{ .allocator = arena });
    defer cli.deinit();

    // Parse help argument.
    if (cli.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &PARAMS, .{});
    }

    // Set up buffered standard output writer.
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    // Write to standard output.
    try writer.writeAll("All your codebase are belong to us.\n");

    // Flush standard output.
    try buf_writer.flush();
}

comptime {
    std.testing.refAllDecls(@This());
}
