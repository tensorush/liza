//! Root source file that exposes the executable's main function to the build system.

const std = @import("std");
const argzon = @import("argzon");

const $p = @import("$p.zig");

// Command-line interface definition.
// TODO: Extract into `cli.zon` after Zig 0.14.1 release.
const cli = .{
    .name = "exe",
    .description = "Executable CLI template.",
    .options = .{
        .{
            .short = 'n',
            .long = "number",
            .type = "u8",
            .default = 3,
            .description = "Number of times to print the string.",
        },
    },
    .positionals = .{
        .{
            .meta = .STRING,
            .type = "string",
            .default = "All your codebase are belong to us.",
            .description = "String to print.",
        },
    },
};

pub fn main() !void {
    // Set up debug allocator
    var gpa_state: std.heap.DebugAllocator(.{}) = .init;
    const gpa = gpa_state.allocator();
    defer if (gpa_state.deinit() == .leak) {
        @panic("Memory leak has occurred!");
    };

    // Create arguments according to CLI definition
    const Args = argzon.Args(cli, .{});

    // Parse command-line arguments
    const args = try Args.parse(gpa, std.io.getStdErr().writer(), .{});

    // Get parsed arguments
    const number = args.options.number;
    const string = args.positionals.STRING;

    // Set up buffered standard output writer
    const std_out = std.io.getStdOut();
    var buf_writer = std.io.bufferedWriter(std_out.writer());
    const writer = buf_writer.writer();

    // Run core logic
    try $p.run(string, number, writer);

    // Flush standard output
    try buf_writer.flush();
}
