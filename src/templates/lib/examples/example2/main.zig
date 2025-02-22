//! Root source file that exposes the library usage example's main function.

const std = @import("std");

pub fn main() !void {
    // Set up general-purpose allocator.
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    // Set up PRNG.
    var prng = std.Random.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    // Set up arena allocator.
    var arena_state = std.heap.ArenaAllocator.init(gpa);
    const arena = arena_state.allocator();
    defer arena_state.deinit();

    // Set up buffered standard output writer.
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    // Write to standard output.
    for (0..random.uintAtMost(u3, std.math.maxInt(u3))) |_| {
        const bytes = try arena.alloc(u8, 3);
        random.bytes(bytes);
        try writer.print("{s}\n", .{bytes});
    }

    // Flush standard output.
    try buf_writer.flush();
}
