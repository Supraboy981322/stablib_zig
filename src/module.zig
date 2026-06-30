const _setup = @import("setup.zig");
const _error = @import("error.zig");

// TODO:
//  - a minimal std.Io implementation for global setup()
//  - make atomic
//      - probably using a wrapper function; called with 'stablib.io()'
pub var io:?@import("std").Io = null;

pub const setup = _setup.do;
pub const SetupErr = _setup.Error;

pub const Error = _error.Error;
