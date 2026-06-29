pub const Error = error {
    Allocator
};
pub fn do(io:@import("std").Io) !void {
    if (@import("alloc.zig").setup(io) != .ok) return error.Allocator;
}
