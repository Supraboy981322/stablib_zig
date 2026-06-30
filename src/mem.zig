const general = @import("general.zig");

const assert = general.assert;
const comptimeAssert = general.comptimeAssert;

pub fn eql(comptime T:type, one:[]const T, two:[]const T) bool {
    if (one.len != two.len) return false;
    for (0..one.len) |i| if (one[i] != two[i]) return false;
    return true;
}
pub fn absorbTerminator(slice:anytype) blk: {
    const T:type = @TypeOf(slice);
    const i = @typeInfo(T);
    comptimeAssert(i == .pointer, "must be a slice");
    assert(i.pointer.size == .slice, "pointer too small");
    break :blk @Pointer(.slice, .{
        .@"const" = i.is_const,
        .@"volatile" = i.is_volatile,
        .@"allowzero" = i.is_allowzero,
        .@"addrspace" = i.address_space,
        .@"align" = i.alignment,
    }, i.child, null);
} {
    const i = @typeInfo(@TypeOf(slice)).pointer;
    return
        if (i.sentinel_ptr == null)
            slice
        else
            slice.ptr[0..slice.len+1];
}

pub fn reverseInPlace(comptime T:type, slice:[]T) void {
    var offset:usize = slice.len;
    for (0..slice.len/2) |i| {
        defer offset -= 1;
        swap(T, &slice[i], &slice[offset-1]);
    }
}
pub fn reverse(comptime T:type, slice:[]const T) []const T {
    var new:[]u8 = @constCast(slice);
    reverseInPlace(T, new[0..]);
    return new;
}

pub fn swap(comptime T:type, one:*T, two:*T) void {
    const tmp = one.*;
    one.* = two.*;
    two.* = tmp;
}
