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

pub const Futex = switch (builtin.os.tag) {
    .linux => struct {
        fn wait(ptr: *const atomic.Value(u32), expect: u32, timeout: ?u64) error{Timeout}!void {
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

            switch (posix.errnoFromSyscall(rc)) {
                .SUCCESS => {}, // notified by `wake()`
                .INTR => {}, // spurious wakeup
                .AGAIN => {}, // ptr.* != expect
                .TIMEDOUT => {
                    assert(timeout != null);
                    return error.Timeout;
                },
                .INVAL => {}, // possibly timeout overflow
                .FAULT => unreachable, // ptr was invalid
                else => unreachable,
            }
        }

        fn wake(ptr: *const atomic.Value(u32), max_waiters: u32) void {
            const rc = linux.futex_3arg(
                &ptr.raw,
                .{ .cmd = .WAKE, .private = true },
                @min(max_waiters, math.maxInt(i32)),
            );

            switch (linux.E.init(rc)) {
                .SUCCESS => {}, // successful wake up
                .INVAL => {}, // invalid futex_wait() on ptr done elsewhere
                .FAULT => {}, // pointer became invalid while doing the wake
                else => unreachable,
            }
        }
    },
    inline else => |t| @compileError("TODO: " ++ @tagName(t)),
};
