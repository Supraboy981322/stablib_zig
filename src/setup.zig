const module = @import("module.zig");
const general = module.general;

const assert = module.assert;

pub const Error = error {
    Allocator
};
pub fn do(io:@import("std").Io) !void {
    assert(module.global_io == null, "module is already setup");
    module.global_io = io;
    if (@import("alloc.zig").setup() != .ok) return error.Allocator;
}
pub fn assertOk() void {
    assert(module.global_io != null, "global library state is not setup");
}
