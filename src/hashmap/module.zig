// TODO:
//  [ ] bones to provide hashing and equality functions
//  [ ] switch standard map to use bones
//  [ ] string hashmap
//      [ ] proto
//      [ ] refactor to use bones (once it's written)
//  [ ] int hashmap
//  [x] BumpMap
//  [x] EnumMap
//  [ ] standard hashmap


const bones = @import("bones.zig");
const enum_map = @import("enum_map.zig");
const standard = @import("standard.zig");
const bump_map = @import("BumpMap.zig");

pub const Bones = bones.Bones;
pub const Standard = standard.HashMap;

pub const EnumMap = enum_map.EnumMap;

const BumpMap = bump_map.BumpMap;
const ByteBumpMap = bump_map.ByteBumpMap;

test "hashmap module" {
    _ = enum_map;
    _ = standard;
    _ = bump_map;
    //_ = bones;
}
