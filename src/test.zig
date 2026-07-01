const module = @import("module.zig");
const DynArr = module.types.DynamicArray;
const testing = @import("testing.zig");
const mem = @import("mem.zig");

// TODO:
//  - implementation of Zig's print formatter
const print = @import("std").debug.print;

const general = module.general;
const assert = general.assert;
const expect = testing.expect;
const expectMany = testing.expectMany;
const expectEqlSlices = testing.expectEqlSlices;
const expectManyEqlSlices = testing.expectManyEqlSlices;
const expectError = testing.expectError;
const assertSetup = module.assertSetup;

var is_setup:bool = false;

pub fn main() !u8 {
    @compileError("this must be run as a test (using 'zig test test.zig')");
}

test "setup()" {
    assert(module.io == null, "global library state shouldn't already be setup");

    const io = @import("std").testing.io;
    try module.setup(io);
    is_setup = true;
}

test "mem.swap(...) ; mem.reverse(...) ; mem.reverseInPlace(...)" {
    assertSetup();

    const str = "foo bar baz";
    const reversed = mem.reverse(u8, str);
    try expectEqlSlices(u8, reversed, "zab rab oof");
    try expectEqlSlices(u8, str, "foo bar baz");
}

test "DynamicArray(...)" {
    assertSetup();

    var buf:DynArr(u8) = try .init(0, .{ .growth_multiplier = 2 });
    defer buf.deinit();

    try expect(buf.pop() == null);

    try buf.append('a');
    try buf.appendSlice("foo");

    const str_1 = buf.string();
    const str_2 = buf.string();
    try expectManyEqlSlices(u8, &.{ str_1, str_2, "afoo", });

    try expectEqlSlices(
        u8,
        "afoo",
        mem.reverse(u8, &.{
            buf.pop().?,
            buf.pop().?,
            buf.pop().?,
            buf.pop().?,
        })
    );
    try expect(buf.pop() == null);
}

test "EnumMap(...)" {
    const Foo = enum { a, b, c, d, e, f, g };
    var map:module.types.hashmap.EnumMap(Foo, u8) = try .init();
    defer map.deinit();

    //basic
    try map.put(.a, 102, .{ .no_clobber = true });
    try map.put(.b, 103, .{ .no_clobber = true });
    try expectMany(&.{
        map.get(.a, .{}).? == 102,
        map.get(.a, .{ .ptr = true }).?.* == try map.get(.a, .{ .err_if_missing = true }),

        map.get(.b, .{}).? == 103,
        map.get(.b, .{ .ptr = true }).?.* == try map.get(.b, .{ .err_if_missing = true }),

        map.get(.c, .{}) == null,
    });

    //errors
    try expectError(error.Missing, map.get(.c, .{ .err_if_missing = true }));
    _ = try map.get(.a, .{ .err_if_missing = true });
}
