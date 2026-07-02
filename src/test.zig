const module = @import("module.zig");
const DynArr = module.types.DynamicArray;
const testing = @import("testing.zig");
const mem = @import("mem.zig");

// TODO:
//  - implementation of Zig's print formatter
const print = @import("std").debug.print;

const types = module.types;
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
    //@compileError("this must be run as a test (using 'zig test test.zig')");
    var mut:types.atomic.Mutex = .{};
    var io:module.io.WithMutex = .init(&mut);
    try io.print(.out, "foo", .{});
    return 0;
}
