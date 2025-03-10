//! Source file that exposes the library's API and test suite to the root source file.

const std = @import("std");

/// Use library API.
pub fn use(arena: std.mem.Allocator, random: std.Random, writer: anytype) !void {
    for (0..3) |_| {
        const len = random.intRangeAtMost(u8, 2, 64);
        const bytes = try arena.alloc(u8, len);
        for (bytes) |*byte| {
            byte.* = random.intRangeAtMost(u8, 'a', 'z');
        }
        try writer.print("Random string of random length {d}: {s}.\n", .{ len, bytes });
    }
}
