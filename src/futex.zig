//usage of stdlib
//  - 'std.os'; very low level, breaks everything if changed
//      so likely won't change too often (I hope)
//      - required for syscalls
// TODO:
//  - 'std.math' implementation
const os = @import("std").os;
const linux = os.linux;
const math = @import("std").math;



const builtin = @import("builtin");
const module = @import("module.zig");
const time = module.time;

const atomic = module.types.atomic;
const assert = module.general.assert;
const posix = module.posix;
const todo = module.todo;

pub const WakeDone = enum {
    ok,              // successful wake up
    was_invalidated, // invalid futex_wait() on ptr done elsewhere
    made_invalid,    // pointer became invalid while doing the wake
};

pub const WaitDone = enum {
    awakened,  //notified by 'wake()'
    spurious,  //spurious wakup
    ptr_value, //ptr.* != expect
    invalid,   //possible overflow of timeout.?
};

pub const futex = switch (builtin.os.tag) {
    .linux => struct {
        const Atomic = atomic.Value(u32, null);
        //timeout in nanoseconds
        pub fn wait(ptr: *const Atomic, expect: u32, timeout: ?u64) error{Timeout}!WaitDone {
            var ts: linux.timespec = undefined;
            if (timeout) |timeout_ns| {
                ts.sec = @as(@TypeOf(ts.sec), @intCast(timeout_ns / time.ns_per_s));
                ts.nsec = @as(@TypeOf(ts.nsec), @intCast(timeout_ns % time.ns_per_s));
            }

            const rc = linux.futex_4arg(
                &ptr.raw,
                .{ .cmd = .WAIT, .private = true },
                expect,
                if (timeout != null) &ts else null,
            );

            return switch (posix.errnoFromSyscall(rc)) {
                .SUCCESS => .awakened,
                .INTR => .spurious,
                .AGAIN => .ptr_value,
                .TIMEDOUT => {
                    assert(timeout != null, "caller of Futex.wait(...) didn't want to timeout");
                    return error.Timeout;
                },
                .INVAL => .invalid,
                .FAULT => unreachable,
                else => unreachable,
            };
        }

        pub fn wake(ptr: *const Atomic, max_waiters: u32) WakeDone {
            if (max_waiters == 0) return .ok;

            const rc = linux.futex_3arg(
                &ptr.raw,
                .{ .cmd = .WAKE, .private = true },
                @min(max_waiters, math.maxInt(i32)),
            );

            return switch (posix.errnoFromSyscall(rc)) {
                .SUCCESS => .ok,
                .INVAL => .was_invalidated,
                .FAULT => .made_invalid,
                else => unreachable,
            };
        }
    },
    inline else => |t| todo(@tagName(t)),
};
