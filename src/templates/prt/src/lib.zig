//! Root source file that exposes the library's API.

const std = @import("std");

pub const c = @cImport({
    @cInclude("lib.h");
});

comptime {
    std.testing.refAllDecls(@This());
}
