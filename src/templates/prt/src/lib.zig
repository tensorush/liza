//! Root file that exposes the public API.

const std = @import("std");

pub const c = @cImport({
    @cInclude("lib.h");
});

test {
    std.testing.refAllDecls(@This());
}
