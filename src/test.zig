const DynArr = @import("DynamicArray.zig").DynamicArray;
const print = @import("std").debug.print;

pub fn main(init:@import("std").process.Init) !u8 {
    try @import("module.zig").setup(init.io);
    var buf:DynArr(u8) = try .init(0, .{ .growth_multiplier = 2 });
    try buf.append('a');
    try buf.appendSlice("foo");
    print(
        \\{d} {x}
        \\|{s}|
        \\{?c} {?c} {?c} {?c} {?c}
    , .{
        buf.len,
        buf.string(),
        buf.string(),
        buf.pop(),
        buf.pop(),
        buf.pop(),
        buf.pop(),
        buf.pop(),
    });
    return 0;
}
