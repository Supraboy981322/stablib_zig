pub const word_size = @sizeOf(usize) * 8;
pub inline fn isWordSize(comptime s:usize) bool {
    comptime return word_size == s;
}
