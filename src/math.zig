const module = @import("module.zig");
const todo = module.general.todo;

pub inline fn maxInt(comptime T:type) T {
    comptime switch (@typeInfo(T)) {
        .int => |info| {
        },
        .float => |info| {
        },
        .comptime_int, .comptime_float => 
    };
}
