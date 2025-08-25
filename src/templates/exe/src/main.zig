//! Root source file that exposes the executable's main function to the build system.

const std = @import("std");

const argzon = @import("argzon");

const $p = @import("$p.zig");

const CLI = @import("cli.zon");

pub fn main() !void {
    // Set up debug allocator
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) @panic("Memory leaked!");

    // Set up standard output writer
    var stdout_buf: [argzon.MAX_BUF_SIZE]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const writer = &stdout_writer.interface;

    // Set up standard error writer
    var stderr_buf: [argzon.MAX_BUF_SIZE]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buf);

    // Allocate process arguments
    var arg_str_iter = try std.process.argsWithAllocator(gpa);
    defer arg_str_iter.deinit();

    // Create arguments according to CLI definition
    const Args = argzon.Args(CLI, .{});

    // Parse command-line arguments
    const args: Args = try .parse(gpa, &arg_str_iter, &stderr_writer.interface, .{});

    // Get parsed arguments
    const number = args.options.number;
    const string = args.positionals.STRING;

    // Run core logic
    try $p.run(string, number, writer);

    // Flush standard output
    try writer.flush();
}
