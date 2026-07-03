const builtin = @import("builtin");
const module = @import("module.zig");
const types = module.types;
const testing = module.testing;
const mem = module.mem;

const Type = types.builtin.Type;
const expect = testing.expect;
const expectMany = testing.expectMany;
const expectEqualMatrices = testing.expectEqlMatrices;
const expectEqualSlices = testing.expectEqlSlices;
const maxInt = module.math.maxInt;

const Module = @This();

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



pub fn MinInt(comptime v:comptime_int) type {
    const foo:u64 = if (v >= 0) @max(v, 1) else @max(-v - 1, -v);
    const bits = 64 - @clz(foo);
    return
        if (module.meetsMinimumVersion())
            @Int(.unsigned, bits)
        else
            @compileError("don't blame me for Zig removing builtins and leaving no way to easily use the conditionally");
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
pub fn enumInts(comptime T:type) [fieldCount(T)]Tag(T) {
    return comptime blk: {
        const count = fieldCount(T);
        const set = fields(T);
        var res = [_]Tag(T){undefined} ** count;
        for (0..set.len) |i| res[i] = set[i].value;
        break :blk res;
    };
}
pub fn FieldEnum(comptime T:type) type {
    comptime {
        const names = fieldNames(T);
        const I = MinInt(names.len);
        var back = [_]I{undefined} ** names.len;
        for (0..names.len) |i| back[i] = @intCast(i);
        if (module.meetsMinimumVersion())
            return @Enum(I, .exhaustive, &names, &back)
        else
            @compileError("don't blame me for Zig removing builtins and leaving no way to easily use the conditionally");
    }
}
pub fn FieldIndexType(comptime T:type, idx:usize) type {
    return fields(T)[idx].type;
}

test "fieldNames(), fields(), FieldType(), and fieldCount()" {
    const Foo = union(enum) {
        bar:[]const u8,
        baz:u0,
    };
    const names = fieldNames(Foo);
    try expectEqualMatrices(u8, &names, &.{ "bar", "baz" });
}



pub fn LazyEnum(comptime field_names:[]const []const u8) type {
    const len = field_names.len;
    const Back = MinInt(len);
    var buf = [_]Back{undefined} ** len;
    return @Enum(
        Back,
        .exhaustive,
        field_names,
        mem.mkRange(Back, len, null, &buf)[0..len]
    );
}

test LazyEnum {
    const BaseLine = enum(u2) { foo, bar, baz };
    const baseline = fieldNames(BaseLine);

    const names = &.{ "foo", "bar", "baz" };
    const T = LazyEnum(names);
    const resulting_names = fieldNames(T);

    try expectMany(&.{
        Tag(T) == Tag(BaseLine),
        mem.eqlMatrices(u8, &resulting_names, &baseline),
        fieldCount(T) == fieldCount(BaseLine),
        mem.manyEql(u2, &.{ &enumInts(T), &enumInts(BaseLine), &.{ 0, 1, 2 } }),
    });
}

// TODO:
//  - evalBranchQuota
//pub fn IntEnum(comptime max:anytype) type {
//    var names = [_][]const u8{undefined} ** max;
//    for (0..max) |num| names[num] = &mem.toBytes(num);
//    const Back = MinInt(max);
//    var buf = [_]Back{undefined} ** max;
//    return @Enum(
//        Back,
//        .exhaustive,
//        names,
//        mem.mkRange(Back, max, null, &buf)[0..max]
//    );
//}
//test IntEnum {
//    const T = IntEnum(maxInt(u8));
//    const names = fieldNames(T);
//    for (names, 0..) |tag, i|try expectMany(&.{ tag.len == 1, tag[0] == i });
//}



pub fn anyToInt(comptime T:type, v:anytype) T {
    return switch (@typeInfo(v)) {
        .@"enum" => @intFromEnum(v),
        .int => v,
        .@"float" => @intFromFloat(v),
        .@"pointer" => @intFromPtr(v),
        else => |t| @compileError("cannot create an int from " ++ @tagName(t)),
    };
}



pub fn Structure(comptime T:type) type {
    return struct {
        structure:T,

        pub const Self = @This();
        pub const Fields = FieldEnum(T);
        const fields = Module.fields(T);

        pub fn init(default:T) Self {
            return .{ .structure = default };
        }


        pub fn Field(comptime field:Fields) type {
            inline for (Self.fields) |f|
                if (field == stringToEnum(Fields, f.name).?)
                    return f.type;
            unreachable;
        }

        pub fn set(self:*Self, comptime field:Fields, value:Field(field)) void {
            inline for (Self.fields) |f|
                if (field == comptime stringToEnum(Fields, f.name).?) {
                    @field(self.structure, f.name) = value;
                    return;
                };
            unreachable;
        }
        pub fn get(self:*Self, comptime field:Fields) Field(field) {
            inline for (Self.fields) |f|
                if (field == comptime stringToEnum(Fields, f.name).?)
                    return @field(self.structure, f.name);
            unreachable;
        }
    };
}
test Structure {
    const T = struct {
        a:usize,
        b:[]const u8,
        c:void,
    };

    var s:Structure(T) = .init(.{
        .a = 83,
        .b = "foo",
        .c = {},
    });
    try expectMany(&.{
        s.get(.a) == 83,
        mem.eql(u8, s.get(.b), "foo"),
        s.get(.c) == {},
    });

    s.set(.b, "bar baz");
    try expectMany(&.{
        s.get(.a) == 83,
        mem.eql(u8, s.get(.b), "bar baz"),
        s.get(.c) == {},
    });
}
