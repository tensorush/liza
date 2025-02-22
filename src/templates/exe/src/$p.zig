//! Source file that exposes the executable's core logic and test suite to the root source file and Autodoc.

const std = @import("std");

/// Run core logic.
pub fn run(pos_arg: []const u8, opt_arg: u8, writer: anytype) !void {
    for (0..opt_arg) |_| {
        try writer.print("{s}\n", .{pos_arg});
    }
}
