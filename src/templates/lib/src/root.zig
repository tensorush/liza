//! Root source file that exposes the library's API to users and Autodoc.

const std = @import("std");

const $p = @import("$p.zig");

pub const use = $p.use;

test {
    std.testing.refAllDecls(@This());
}
