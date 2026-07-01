//usage of stdlib
//  - 'std.os'; very low level, breaks everything if changed
//      so likely won't change too often (I hope)
//      - required for syscalls
const os = @import("std").os;
const linux = os.linux;

const builtin = @import("builtin");

pub const posix = switch (builtin.target.os.tag) {
    .linux => struct {
        pub fn syscallOk(rc:usize) bool {
            return errnoFromSyscall(rc) == .SUCCESS;
        }
        pub fn errnoFromSyscall(r:usize) linux.E {
            const s: isize = @bitCast(r);
            const i = if (s > -4096 and s < 0) -s else 0;
            return @enumFromInt(i);
        }
    },
    inline else => |t| @compileError("TODO: " ++ @tagName(t)),
};
