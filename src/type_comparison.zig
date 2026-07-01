const module = @import("module.zig");
const general = module.general;
const mem = module.mem;
const meta = module.meta;
const types = module.types;

const builtin = types.builtin;
const comptimeAssert = general.comptimeAssert;
const activeTag = meta.activeTag;
const allTrue = general.allTrue;

pub const strict = struct {

    // NOTE:
    //  - you can provide:
    //      a type and a value (or vice versa),
    //      two types,
    //      two values
    //  - this only compares the types (meaning the value is ignored)
    // TODO:
    //  - a 'meta.walkType' module with a 'eql' generic function to
    //      walk stuff like structs and unions, with 'eql' just to
    //        comparing the value of each field (handling things like slices)
    //          this would allow this function to just be:
    //      comptime {
    //          const T1, const T2 = .{
    //              if (@TypeOf(one) == type) one else @TypeOf(one),
    //              if (@TypeOf(two) == type) two else @TypeOf(two),
    //          };
    //          const o, const t = .{ @typeInfo(T1), @typeInfo(T2) };
    //          return meta.compare.eql(@typeInfo(T1, T2);
    //      }
    pub fn enumerations(one:anytype, two:anytype) bool {
        comptime {
            const T1, const T2 = .{
                if (@TypeOf(one) == type) one else @TypeOf(one),
                if (@TypeOf(two) == type) two else @TypeOf(two),
            };
            const o, const t = .{ @typeInfo(T1), @typeInfo(T2) };
            comptimeAssert(o == .@"enum" and t == .@"enum");
            const e1, const e2 = .{ o.@"enum", t.@"enum" };
            return allTrue(&.{
                e1.tag_type == e2.tag_type,
                e1.is_exhaustive == e2.is_exhaustive,
                blk: {
                    const f1, const f2 = .{ e1.fields, e2.fields };
                    if (f1.len != f2.len) break :blk false;
                    for (0..f1.len) |i| if (!allTrue(&.{
                        mem.eql(u8, f1[i].name, f2[i].name),
                        f1[i].value == f2[i].value,
                    }))
                        return false;
                    break :blk true;
                },
                blk: {
                    const f1, const f2 = .{ e1.decls, e2.decls };
                    if (f1.len != f2.len) break :blk false;
                    for (0..f1.len) |i|
                        if (!mem.eql(u8, f1[i].name, f2[i].name))
                            return false;
                    break :blk true;
                },
            });
        }
        unreachable;
    }
};

pub const loose = struct {
    pub fn matches(comptime T:type, comptime what:builtin.Type) bool {
        activeTag(@typeInfo(T)) == activeTag(what);
    }
    pub fn is(comptime T:type, comptime what:builtin.TypeEnum) bool {
        return activeTag(@typeInfo(T)) == what;
    }
};
