const module = @import("module.zig");
const general = module.general;
const types = module.types;
const testing = module.testing;

const assertSetup = module.assertSetup;
const expectEqlSlices = testing.expectEqlSlices;
const assert = general.assert;
const comptimeAssert = general.comptimeAssert;

const Matrix = types.Matrix;

// TODO:
//  - probably could put more here
pub const Where = enum {
    stack,
    alloc,
};

pub const Sentinel = enum(u8) {
    nul = 0,
    _,
    pub fn num(comptime n:u8) Sentinel {
        return @enumFromInt(n);
    }
    pub fn byte(self:Sentinel) u8 {
        return @intFromEnum(self);
    }
};



//equality
pub fn eql(comptime T:type, one:[]const T, two:[]const T) bool {
    if (one.len != two.len) return false;
    for (0..one.len) |i| if (one[i] != two[i]) return false;
    return true;
}
pub fn manyEql(comptime T:type, slices:Matrix(T)) bool {
    if (slices.len >= 2)
        for (slices[1..]) |s|
            if (!eql(T, s, slices[0])) return false;
    return true;
}

//all values in a slice are the same
//(as opposed to two slices being equal to each other)
// TODO:
//  - would it be better to recurse for arbitrary depth of slices of slices?
pub fn allEql(comptime T:type, slice:[]const T) bool {
    if (slice.len >= 2)
        return allEqlTo(T, slice[1..], slice[0]);
    return true;
}
pub fn allEqlTo(comptime T:type, slice:[]const T, to:T) bool {
    for (slice) |v| if (v != to) return false;
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

test "mem.swap(...) ; mem.reverse(...) ; mem.reverseInPlace(...)" {
    assertSetup();

    const str = "foo bar baz";
    const reversed = reverse(u8, str);
    try expectEqlSlices(u8, reversed, "zab rab oof");
    try expectEqlSlices(u8, str, "foo bar baz");
}
