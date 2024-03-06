//! Root library file that exposes the public API.

const std = @import("std");

test {
    std.testing.refAllDecls(@This());
}
