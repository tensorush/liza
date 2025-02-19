//! Source file that exposes the core logic to the main function and Autodoc.

const std = @import("std");

pub fn run(writer: anytype) !void {
    try writer.writeAll("All your codebase are belong to us.\n");
}
