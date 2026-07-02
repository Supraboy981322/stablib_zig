const module = @import("module.zig");
const general = module.general;
const types = module.types;
const testing = module.testing;
const meta = module.meta;

const expect = testing.expect;
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



//checks if two slices are equal
//  eg: for two strings, both strings are equal
//    true: eql(u8, "foo", "foo")
//    false: eql(u8, "foo", "bar")
pub fn eql(comptime T:type, one:[]const T, two:[]const T) bool {
    if (one.len != two.len) return false;
    for (0..one.len) |i| if (one[i] != two[i]) return false;
    return true;
}
//checks if every row in one matrix has the same values;
//  eg: in a slice of strings, every string is equal
//    true: manyEql(u8, &.{ "foo", "foo", "foo" })
//    false: manyEql(u8, &.{ "foo", "bar", "baz" })
pub fn manyEql(comptime T:type, slices:Matrix(T)) bool {
    if (slices.len >= 2)
        for (slices[1..]) |s|
            if (!eql(T, s, slices[0])) return false;
    return true;
}
//checks if each row in two matrices are equal; as oppossed to
//  every row in one matrix having the same values
//    eg: two slices of integer sequences have the same sequences at the same index
//      true: eqlMatrices(u8, &.{ "foo", "bar", "baz" }, &.{ "foo", "bar", "baz" })
//      false: eqlMatrices(u8, &.{ "baz", "bar", "foo" }, &.{ "foo", "bar", "baz" })
pub fn eqlMatrices(comptime T:type, one:Matrix(T), two:Matrix(T)) bool {
    if (one.len != two.len) return false;
    for (0..one.len) |r|
        if (!eql(T, one[r], two[r])) return false;
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
test "allEql(...) > allEqlTo(...)" {
    assertSetup();

    var str  = [_]u8{'a'} ** 1024;
    try expect(allEql(u8, &str));
    for (0..str.len) |i| {
        var s = str;
        s[i] = 'f';
        try expect(!allEql(u8, &s));
    }
}

pub inline fn contains(comptime T:type, slice:[]const T, b:u8) bool {
    return for (slice) |c| {
        if (c == b) break true;
    } else false;
}
test "contains(...)" {
    assertSetup();

    try expect(contains(u8, "qwertz", 'r'));
    try expect(!contains(usize, &.{ 0, 98_234, 256, 0o654 }, 3));
}



pub fn mkRange(comptime T:type, len:T, skip:?T, buf:[]T) []const T {
    for (0..len) |i| {
        if (skip) |s|
            if (@mod(i, s) == 0) continue;
        buf[i] = i;
    }
    return buf;
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
