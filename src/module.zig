const _setup = @import("setup.zig");
const _error = @import("error.zig");

// TODO:
//  - a minimal std.Io implementation for global setup()
//  - make atomic
//      - probably using a wrapper function; called with 'stablib.io()'
pub var global_io:?@import("std").Io = null;

test "setup()" {
    try testing.expect(global_io == null);
    const _io = @import("std").testing.io;
    try setup(_io);
    try testing.expect(global_io != null);
}

pub const setup = _setup.do;
pub const SetupErr = _setup.Error;
pub const assertSetup = _setup.assertOk;

pub const general = @import("general.zig");
pub const types = @import("types.zig");
pub const posix = @import("posix.zig").posix;
pub const testing = @import("testing.zig");
pub const meta = @import("meta.zig");
pub const time = @import("time.zig");
pub const mem = @import("mem.zig");
pub const alloc = @import("alloc.zig");
pub const fmt = @import("fmt.zig");
pub const io = @import("io.zig");
pub const sys = @import("sys.zig");

pub const todo = general.todo;
pub const assert = general.assert;
pub const comptimeAssert = general.comptimeAssert;

pub const Error = _error.Error;

test "general" {
    _ = general;
    _ = types;
    _ = posix;
    _ = testing;
    _ = meta;
    _ = time;
    _ = mem;
    _ = alloc;
    _ = fmt;
    _ = io;
}
