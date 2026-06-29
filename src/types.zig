const meta = @import("meta.zig");
pub const builtin = struct {
    pub const Type = @TypeOf(@typeInfo(u8));
};

pub const HashMap = @import("hashmap.zig").HashMap;

pub const SetupStatus = enum(u1) {
    ok,
    failed
};

// TODO: probably something more can be done here
pub fn Matrix(comptime T:type) type {
    return []const []const T;
}

// TODO: not enough for some types
pub fn is(comptime T:type, comptime what:builtin.Type) bool {
    meta.activeTag(@typeInfo(T)) == meta.activeTag(what);
}
