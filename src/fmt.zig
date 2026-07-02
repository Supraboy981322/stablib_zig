//usage of stdlib
//   - 'std.fmt.bufPrint' is symlinked here
// TODO:
//   - an implementation of it
pub const bufPrint = @import("std").fmt.bufPrint;

const module = @import("module.zig");
const mem = module.mem;
const ascii = module.ascii;

const isDigit = ascii.isDigit;

const Sentinel = mem.Sentinel;
const assert = module.general.assert;


pub const parser = @import("parser/module.zig");


//copies string into buffer with provided sentinel value
pub fn toSentinel(str:[]const u8, comptime s:Sentinel, comptime max_len:usize) ![max_len-1:s.byte()]u8 {
    var buf:[max_len-1:s.byte()]u8 = undefined;
    if (str.len >= buf.len) return error.SliceTooLong;
    @memcpy(buf[0..str.len], str);
    buf[str.len] = @intFromEnum(s);
    return buf;
}



pub fn parseInt(comptime T:type, str:[]const u8) !T {
    var res:T = 0;
    for (0..str.len) |i| {
        const b = str[i];
        if (!isDigit(b) and b != '_') return error.NotANumber;
        // TODO: not a very smart way to do this
        const old = res;
        res *%= 10;
        res +%= b - '0';
        if (old > res) return error.Overflow;
    }
    return res;
}
