//! Root source file that exposes the library's API.

const std = @import("std");

comptime {
    std.testing.refAllDecls(@This());
}
