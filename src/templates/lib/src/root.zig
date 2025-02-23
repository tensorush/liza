//! Root source file that exposes the library's API to users and Autodoc.

const std = @import("std");

test {
    std.testing.refAllDecls(@This());
}
