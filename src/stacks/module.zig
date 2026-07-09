pub const BasicStack = @import("BasicStack.zig").BasicStack;


pub fn BasicByteStack(comptime size:usize) type {
    return BasicStack(u8, size);
}
pub fn BasicBitStack(comptime size:usize) type {
    return BasicStack(u1, size);
}


test "stacks" {
    _ = BasicStack;
    _ = BasicBitStack;
    _ = BasicByteStack;
}
