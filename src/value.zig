pub fn MkBufOpts(comptime T:type) type {
    return struct { val:?T = null };
}
//creates an initialized buffer with an optional fill value
pub inline fn mkBuf(comptime T:type, comptime len:usize, comptime opts:MkBufOpts(T)) [len]T {
    return [_]T{ if (opts.val) |v| v else undefined } ** len;
}
