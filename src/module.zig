const _setup = @import("setup.zig");
const _error = @import("error.zig");

// TODO:
//  - a minimal std.Io implementation for global setup()
//  - make atomic
//      - probably using a wrapper function; called with 'stablib.io()'
pub var io:?@import("std").Io = null;

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

pub const Error = _error.Error;
