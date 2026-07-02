//usage of stdlib
//   - 'std.fmt.bufPrint' is symlinked here
// TODO:
//   - an implementation of it
pub const bufPrint = @import("std").fmt.bufPrint;

const module = @import("module.zig");
const mem = module.mem;

const Sentinel = mem.Sentinel;
const assert = module.general.assert;

//copies string into buffer with provided sentinel value
pub fn toSentinel(str:[]const u8, comptime s:Sentinel, comptime max_len:usize) ![max_len-1:s.byte()]u8 {
    var buf:[max_len-1:s.byte()]u8 = undefined;
    if (str.len >= buf.len) return error.SliceTooLong;
    @memcpy(buf[0..str.len], str);
    buf[str.len] = @intFromEnum(s);
    return buf;
}
