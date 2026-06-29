const _setup = @import("setup.zig");
const _error = @import("error.zig");

pub const setup = _setup.do;
pub const SetupErr = _setup.Error;

pub const Error = _error.Error;
