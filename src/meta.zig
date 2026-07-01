const module = @import("module.zig");
const types = module.types;
const testing = module.testing;
const mem = module.mem;

const Type = types.builtin.Type;
const expect = testing.expect;
const expectEqualMatrices = testing.expectEqlMatrices;
const expectEqualSlices = testing.expectEqlSlices;

//misc
pub fn stringToEnum(comptime T:type, name:[]const u8) ?T {
    inline for (comptime fieldNames(T)) |field| {
        if (mem.eql(u8, field, name)) return @field(T, field);
    }
    return null;
}
test "stringToEnum" {
    const Foo = enum{ bar, baz };
    const e = stringToEnum(Foo, "baz");
    try expect(e == .baz);
}



//tags
pub fn Tag(comptime T:type) type {
    return comptime switch (@typeInfo(T)) {
        .@"enum" => |i| i.tag_type,
        .@"union" => |i| i.tag_type orelse @compileError("not tagged"),
        else => @compileError("not a union or enum"),
    };
}
pub fn activeTag(v:anytype) Tag(@TypeOf(v)) {
    return @as(Tag(@TypeOf(v)), v);
}

test "activeTag() and Tag()" {
    const foo:union(enum){ bar, baz } = .baz;
    try expectEqualSlices(u8, "baz", @tagName(activeTag(foo)));
}



//field things
pub fn fieldCount(comptime T:type) usize {
    return switch (@typeInfo(T)) {
        .@"enum" => |i| i.fields.len,
        .@"union" => |i| i.fields.len,
        .@"struct" => |i| i.fields.len,
        .error_set => |i| (i orelse return 0).len,
        else => @compileError("type (" ++ @typeName(T) ++ "has no fields"),
    };
}
pub fn FieldType(comptime T:type) type {
    return switch (@typeInfo(T)) {
        .@"enum" => Type.EnumField,
        .@"union" => Type.UnionField,
        .@"struct" => Type.StructField,
        .error_set => Type.Error,
        else => @compileError("type (" ++ @typeName(T) ++ "has no fields"),
    };
}
pub fn fields(comptime T:type) []const FieldType(T) {
    return switch (@typeInfo(T)) {
        .@"enum" => |info| info.fields,
        .@"struct" => |info| info.fields,
        .@"union" => |info| info.fields,
        .error_set => |errs| errs.?, //is null if not a defined error set
        else => @compileError("type (" ++ @typeName(T) ++ "has no fields"),
    };
}
pub fn fieldNames(comptime T:type) [fieldCount(T)][]const u8 {
    return comptime blk: {
        const len = fieldCount(T);
        var res = [_][]const u8{undefined} ** len;
        for (fields(T)[0..len], 0..len) |field, i| res[i] = field.name;
        break :blk res;
    };
}

test "fieldNames(), fields(), FieldType(), and fieldCount()" {
    const Foo = union(enum) {
        bar:[]const u8,
        baz:u0,
    };
    const names = fieldNames(Foo);
    try expectEqualMatrices(u8, &names, &.{ "bar", "baz" });
}
