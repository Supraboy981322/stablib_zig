const module = @import("module.zig");
const general = @import("general.zig");

pub const Error = error {
    Allocator
};
pub fn do(io:@import("std").Io) !void {
    module.io = io;
    if (@import("alloc.zig").setup() != .ok) return error.Allocator;
}
pub fn assertOk() void {
    general.assert(module.io != null, "global library state is not setup");
}
