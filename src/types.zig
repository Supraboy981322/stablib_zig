const module = @import("module.zig");
const meta = module.meta;
const general = module.general;

const assert = general.assert;
const comptimeAssert = general.comptimeAssert;
const comptimeAssertMany = general.comptimeAssertMany;
const expect = module.testing.expect;
const activeTag = meta.activeTag;

pub const builtin = struct {
    pub const Type = @TypeOf(@typeInfo(u8));
    pub const TypeEnum = meta.Tag(Type);
};

pub const hashmap = @import("hashmap.zig");
pub const HashMap = hashmap.HashMap;

pub const DynamicArray = @import("DynamicArray.zig").DynamicArray;

const Error = @import("error.zig").Error;

pub const compare = @import("type_comparison.zig");

pub const iterators = @import("iterators.zig");

pub const Futex = @import("futex.zig").Futex;

pub const SetupStatus = enum(u1) {
    ok,
    failed
};

// TODO: probably something more can be done here
pub fn Matrix(comptime T:type) type {
    return []const []const T;
}

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
        state:atomic.Value(Lock) = .init(.unlocked, null),

        // TODO: can this even be an enum?
        const Lock = enum(u32) {
            unlocked = 0b00,
            locked = 0b01,
            contended = 0b11,
        };

        pub const init:Mutex = .{ .thing = .init(false, null) };

        pub fn lock(self:*Mutex) void {
            if (self.state.get() == .contended)
                Futex.wait(&self.state, .contended);
            while (self.state.swap(.contended, .acquire) != .unlocked)
                Futex.wait(&self.state, .contended);
        }
        pub fn unlock(self:*Mutex) void {
            const state = self.state.swap(.unlocked, .release);
            assert(state != .unlocked);
            if (state == .contended) Futex.wake(&self.state, 1);
        }

        test "atomic.Mutex" {
            const mut:Mutex = .init;
            mut.lock();
        }
    };
    pub fn Value(comptime T:type, comptime atomic_order:?AtomicOrder) type {
        return extern struct {
            raw:T,

            const Self = @This();

            pub fn init(v:T) Self {
                return .{ .raw = v };
            }

            pub const Order = if (atomic_order) |_| void else AtomicOrder;

            pub fn set(self:*Self, value:T, order:Order) void {
                const o = if (atomic_order) |o| o else order;
                @atomicStore(T, &self.raw, value, @enumFromInt(@intFromEnum(o)));
            }
            pub fn get(self:*Self, order:Order) T {
                const o = if (atomic_order) |o| o else order;
                return @atomicLoad(T, &self.raw, @enumFromInt(@intFromEnum(o)));
            }
            pub fn swap(self:*Self, op:T, order:Order) T {
                const o = if (atomic_order) |o| o else order;
                return @atomicRmw(T, &self.raw, .Xchg, op, @enumFromInt(@intFromEnum(o)));
            }
        };
    }
};
