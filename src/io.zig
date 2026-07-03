const module = @import("module.zig");

const fmt = module.fmt;
const time = module.time;
const posix = module.posix;
const types = module.types;

const Mutex = types.atomic.Mutex;
pub const Fd = posix.Fd;
const bufPrint = fmt.bufPrint;
const Atomic = types.atomic.Value;

const io = @This();

var mutex:Mutex = .{};

var disable_mutex:Atomic(bool, .seq_cst) = .init(false);

pub const NamedOpts = struct {
    bypass_mutex:bool = false,
};
fn lock() void {
    if (!disable_mutex.get({})) mutex.lock();
}
fn unlock() void {
    if (!disable_mutex.get({})) mutex.unlock();
}

pub fn disableMutex() error{AlreadyDisabled}!void {
    if (disable_mutex.get({})) return error.AlreadyDisabled;
    disable_mutex = true;
}

// TODO:
//  - this is super inefficient
//  - this *will* fail if formatted string would be larger than (length of msg) + (size of args)
pub fn print(fd:Fd, comptime msg:[]const u8, args:anytype) !void {
    lock(); defer unlock();
    var buf:[msg.len + @sizeOf(@TypeOf(args))]u8 = undefined;
    const str = bufPrint(&buf, msg, args) catch unreachable; // TODO: refactor print
    try posix.print(fd, str);
}

pub fn write(fd:Fd, bytes:[]const u8) !void {
    lock(); defer unlock();
    try posix.writeAll(fd.value(), bytes);
}
