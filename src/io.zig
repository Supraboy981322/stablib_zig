const module = @import("module.zig");

const fmt = module.fmt;
const posix = module.posix;
const Mutex = module.types.atomic.Mutex;

pub const Fd = posix.Fd;
const bufPrint = fmt.bufPrint;

const io = @This();

// TODO:
//  - this is super inefficient
//  - this *will* fail if formatted string would be larger than 
pub fn print(fd:Fd, comptime msg:[]const u8, args:anytype) !void {
    var buf:[msg.len + @sizeOf(@TypeOf(args))]u8 = undefined;
    const str = bufPrint(&buf, msg, args) catch unreachable; // TODO: refactor print
    try posix.print(fd, str);
}

pub const WithMutex = struct {
    mut:Mutex,

    pub fn init(mut:*Mutex) WithMutex {
        return .{ .mut = mut.* };
    }

    pub fn print(self:*WithMutex, fd:Fd, comptime msg:[]const u8, args:anytype) !void {
        self.mut.lock();
        defer self.mut.unlock();
        try io.print(fd, msg, args);
    }

    // TODO: async of some kind to test this
};

test WithMutex {
    _ = WithMutex;
}

test "basic" {
}
