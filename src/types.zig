const module = @import("module.zig");
const meta = module.meta;
const general = module.general;

const assert = general.assert;
const comptimeAssert = general.comptimeAssert;
const comptimeAssertMany = general.comptimeAssertMany;
const expect = module.testing.expect;
const activeTag = meta.activeTag;
const expectError = module.testing.expectError;

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

pub const futex = @import("futex.zig").futex;

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
            compare.strict.enumerations(Real, AtomicOrder),
            "Zig std.builtin.AtomicOrder changed; update here",
        );
    }

    pub const Mutex = struct {
        state:atomic.Value(u32, null) = .init(unlocked),

        // TODO: can this even be an enum?
        const unlocked:u32 = 0b00;
        const locked:u32 = 0b01;
        const contended:u32 = 0b11;

        pub fn lock(self:*Mutex) void {
            self.lockTimeout(null) catch unreachable;
        }
        pub fn unlock(self:*Mutex) void {
            const state = self.state.swap(unlocked, .release);
            assert(state != unlocked, "mutex already unlocked");
            if (state == contended) _ = futex.wake(&self.state, 1);
        }
        //timeout in ns, null for no timeout
        pub fn lockTimeout(self:*Mutex, timeout:?u64) error{Timeout}!void {
            if (self.state.get(.monotonic) == contended)
                _ = try futex.wait(&self.state, contended, timeout);
            while (self.state.swap(contended, .acquire) != unlocked)
                _ = try futex.wait(&self.state, contended, timeout);
        }

        pub fn isLocked(self:*Mutex) bool {
            self.lockTimeout(1) catch return true;
            self.unlock();
            return false;
        }
        test "isLocked" {
            var mut:Mutex = .{};
            try expect(!mut.isLocked());
            mut.lock();
            try expect(mut.isLocked());
            mut.unlock();
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

            pub fn set(self:*Self, value:T, comptime order:Order) void {
                const o = if (atomic_order) |o| o else order;
                @atomicStore(T, &self.raw, value, @enumFromInt(@intFromEnum(o)));
            }
            pub fn get(self:*Self, comptime order:Order) T {
                const o = if (atomic_order) |o| o else order;
                return @atomicLoad(T, &self.raw, @enumFromInt(@intFromEnum(o)));
            }
            pub fn swap(self:*Self, op:T, comptime order:Order) T {
                const o = if (atomic_order) |o| o else order;
                return @atomicRmw(T, &self.raw, .Xchg, op, @enumFromInt(@intFromEnum(o)));
            }
        };
    }
    test "Mutex ; Value" {
        var mut:Mutex = .{};
        mut.lock();
        try expectError(error.Timeout, mut.lockTimeout(100));
        mut.unlock();
        try mut.lockTimeout(100);
    }
};

test "imports" {
    _ = atomic;
    _ = hashmap;
    _ = @import("DynamicArray.zig");
    _ = @import("error.zig");
    _ = iterators;
    _ = compare;
    _ = @import("futex.zig");
    _ = futex;
}
