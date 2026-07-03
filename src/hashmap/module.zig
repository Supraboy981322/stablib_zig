const enum_map = @import("enum_map.zig");
const standard = @import("standard.zig");

pub const Standard = standard.HashMap;
pub const EnumMap = enum_map.EnumMap;

test "hashmap module" {
    _ = enum_map;
    _ = standard;
}
