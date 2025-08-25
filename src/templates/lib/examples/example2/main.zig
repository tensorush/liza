//! Root source file that exposes the library usage example's main function.

const std = @import("std");

const $p = @import("$p");

const MAX_BUF_SIZE = 1 << 12;

pub fn main() !void {
    // Set up debug allocator
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) @panic("Memory leaked!");

    // Set up arena allocator
    var arena_state: std.heap.ArenaAllocator = .init(gpa);
    const arena = arena_state.allocator();
    defer arena_state.deinit();

    // Set up PRNG
    var prng: std.Random.DefaultPrng = .init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const random = prng.random();

    // Set up standard output writer
    var stdout_buf: [MAX_BUF_SIZE]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout_writer.interface;

    // Use library API
    try $p.use(arena, random, writer);

    // Flush standard output
    try writer.flush();
}
