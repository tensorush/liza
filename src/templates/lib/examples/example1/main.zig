//! Root example file that exposes the main function.

const std = @import("std");

pub fn main() !void {
    // Set up general-purpose allocator.
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer if (gpa.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    // Set up arena allocator.
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    // Set up buffered standard output writer.
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    // Write to standard output.
    try writer.writeAll("All your codebase are belong to us.\n");

    // Flush standard output.
    try buf_writer.flush();
}
