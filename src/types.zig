const meta = @import("meta.zig");
const general = @import("general.zig");

const comptimeAssert = general.comptimeAssert;
const comptimeAssertMany = general.comptimeAssertMany;
const activeTag = meta.activeTag;

pub const builtin = struct {
    pub const Type = @TypeOf(@typeInfo(u8));
    pub const TypeEnum = meta.Tag(Type);
};

pub const HashMap = @import("hashmap.zig").HashMap;

pub const SetupStatus = enum(u1) {
    ok,
    failed
};

// TODO: probably something more can be done here
pub fn Matrix(comptime T:type) type {
    return []const []const T;
}

pub const compare = @import("type_comparison.zig");
pub const is = compare.loose.is;

pub const atomic = struct {
    //ripped straight from stdlib
    pub const AtomicOrder = enum {
        unordered,
        monotonic,
        acquire,
        release,
        acq_rel,
        seq_cst,
    };
    //idotically, Zig's atomic builtins use a param type only
    //  available from stdlib this verifies that it still matches,
    //    because I do not trust it to even remain defined in the
    //      standard library
    comptime {
        const std = @import("std");
        const Real = std.builtin.AtomicOrder;
        comptimeAssert(
            compare.strict.enumerations(Real, AtomicOrder)
        );
    }

    pub const Mutex = struct {
        lock_value:atomic.Value(bool),
        pub const init:Mutex = .{ .thing = .init(false) };
        // TODO
    };
    pub fn Value(comptime T:type) type {
        return struct {
            raw:T,

            const Self = @This();

            pub fn init(v:T) Self {
                return .{ .raw = v };
            }

            pub fn set(self:*Self, value:T) void {
                @atomicStore(T, &self.raw, value, .seq_cst);
            }
        };
    }
};
