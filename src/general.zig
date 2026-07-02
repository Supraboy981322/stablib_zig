const module = @import("module.zig");
const mem = module.mem;

pub inline fn assert(passed:bool, comptime msg:[]const u8) void {
    if (!passed) @panic("assertion failure\n\t" ++ msg);
}
pub fn assertMany(conditions:[]const bool, comptime msg:[]const u8) void {
    inline for (conditions) |condition| assert(condition, msg);
}

pub inline fn comptimeAssert(passed:bool, comptime msg:[]const u8) void {
    if (!passed) @compileError("(comptime) assertion failure\n\t" ++ msg);
}
pub fn comptimeAssertMany(conditions:[]const bool, comptime msg:[]const u8) void {
    inline for (conditions) |condition| comptimeAssert(condition, msg);
}



pub fn allTrue(conditions:[]const bool) bool {
    return mem.allEqlTo(bool, conditions, true);
}



pub fn todo(comptime msg:[]const u8, comptime when:enum{ running, compiling }) noreturn {
    const txt = "TODO (" ++ @tagName(when) ++ "): " ++ msg;
    switch (comptime when) {
        .running => @panic(txt),
        .compiling => @compileError(txt),
    }
}
