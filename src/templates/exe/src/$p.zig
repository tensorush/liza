//! Source file that exposes the executable's API and test suite to users, Autodoc, and the build system.

const std = @import("std");

/// Run core logic.
pub fn run(string: [:0]const u8, number: u8, writer: anytype) !void {
    for (0..number) |_| {
        try writer.print("{s}\n", .{string});
    }
}

test {
    std.testing.refAllDecls(@This());
}
