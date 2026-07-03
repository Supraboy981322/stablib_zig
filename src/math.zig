const module = @import("module.zig");

const testing = module.testing;

const expect = testing.expect;
const expectMany = testing.expectMany;
const todo = module.general.todo;

const print = module.io.print;

pub inline fn maxInt(comptime T:type) T {
    comptime switch (@typeInfo(T)) {
        .int => |info| {
            const bits = info.bits;
            if (bits == 0) return 0;
            const signed = info.signedness == .signed;
            if (signed) {
                if (bits == 1) return 0;
                return (1 << (bits - 1)) -% 1;
            } else
                return (1 << bits) -% 1;
        },
        .float => |info| {
            _ = info;
            todo("maxInt(...) for floats", .compiling);
        },
        .comptime_int, .comptime_float => todo("aren't these bigInt?", .compiling),
        else => @compileError("not int"),
    };
}

pub fn minInt(comptime T:type) T {
    const info = @typeInfo(T);
    if (info == .int) {
        const i = info.int;
        if (i.bits == 0) return 0;
        if (i.signedness == .signed and i.bits == 1) return -1;
    }
    return maxInt(T) +% 1;
}

test "maxInt and minInt" {
    try expectMany(&.{
        maxInt(u8) == 255,
        maxInt(u3) == 7,
        maxInt(u2) == 3,
        maxInt(u1) == 1,
        maxInt(u0) == 0,

        maxInt(i8) == 127,
        maxInt(i3) == 3,
        maxInt(i2) == 1,
        maxInt(i1) == 0,
        maxInt(i0) == 0,
    });

    try expectMany(&.{
        minInt(u8) == 0,
        minInt(u0) == 0,

        minInt(i2) == -2,
        minInt(i1) == -1,
        minInt(i0) == 0,
    });
}
