const stablib = @import("module.zig");

const typeIsNum = stablib.meta.typeIsNum;
const isInt = stablib.meta.isInt;
const isFloat = stablib.meta.isFloat;
const comptimeAssert = stablib.comptimeAssert;


pub fn floatFromBool(comptime T:type, v:bool) T {
    const B:type = @Int(.signed, @typeInfo(T).float.bits);
    return @floatFromInt(@as(B, @intFromBool(v)));
}

pub inline fn float32(v:anytype) f32 {
    return toFloatOrInt(f32, v);
}
pub inline fn float64(v:anytype) f64 {
    return toFloatOrInt(f64, v);
}
pub inline fn int32(v:anytype) i32 {
    return toFloatOrInt(i32, v);
}
pub inline fn int64(v:anytype) i64 {
    return toFloatOrInt(i64, v);
}

pub fn toFloatOrInt(comptime Want:type, val:anytype) Want {
    const T, const v = blk: {
        const T = @TypeOf(val);
        if (T == bool) break :blk .{ u1, @intFromBool(val) };
        break :blk .{ T, val };
    };
    comptime {
        const both_num = typeIsNum(T) and typeIsNum(Want);
        const have = @typeName(T);
        const want = @typeName(Want);
        const msg = "not a number (" ++ have ++ " or " ++ want ++ ")";
        comptimeAssert(both_num, msg);
    }
    return switch (@typeInfo(Want)) {
        .float => if (comptime isInt(T)) @floatFromInt(v) else @floatCast(v),
        .int => if (comptime isInt(T)) @intCast(v) else @intFromFloat(v),
        else => @compileError("cannot divTrunc to non-numeric type"),
    };
}
