//usage of stdlib:
//  - std.testing.allocator: used for tests
//steps/plans to/taken (to) replace/remove usage of stdlib
//  - no current plans, I do not currently have the desire to write a proper testing allocator

const test_alloc = @import("std").testing.allocator;

const stablib = @import("../module.zig");

const float32 = stablib.types.conversion.float32;
const NoError = stablib.types.NoError;
const assert = stablib.assert;

const alloc = stablib.alloc.interface;

pub fn BasicStack(comptime T:type, comptime size:usize) type {
    return struct {
        top:[*]T,
        end:[*]T,

        const Self = @This();

        pub fn init(buf:*[size]T) error{OutOfMemory}!Self {
            return .{
                .top = buf[0..size].ptr,
                .end = buf[size..].ptr,
            };
        }

        pub const SizeChange = union(enum(u1)) {
            amount:usize,
            multiplier:f16,
        };

        pub fn push(self:*Self, value:T) error{StackOverflow}!void {
            self.top[0] = value;
            if (@intFromPtr(self.top+1) > @intFromPtr(self.end)) return error.StackOverflow;
            self.top += 1;
        }

        pub fn pop(self:*Self) error{StackUnderflow}!T {
            if (@intFromPtr(self.top-1) < @intFromPtr(self.end - size)) return error.StackUnderflow;
            self.top -= 1;
            return self.top[0];
        }

        pub fn reset(self:*Self) void {
            self.top = self.end - size;
        }

        pub fn len(self:*Self) usize {
            assert(@intFromPtr(self.top) <= @intFromPtr(self.end), "stack overflow");
            return self.top - (self.end - size);
        }

        pub fn slice(self:*Self) []const T {
            return (self.end - size)[0..self.len()];
        }

        test "some assumptions made" {
            var buf:[size]T = undefined;
            var top:[*]T = buf[0..size].ptr;
            const end:[*]T = buf[size..].ptr;
            for (0..size) |n| {
                try expect((end - top) == size-n);
                top += 1;
            }
            try expect(top - (end - size) == size);

            top = buf[0..size].ptr;
            try expect(top - (end - size) == 0);
        }
    };
}


const expect = stablib.testing.expect;
const expectEqlSlices = stablib.testing.expectEqlSlices;
const expectError = stablib.testing.expectError;


test BasicStack {
    _ = BasicStack(u1, 0);
}

test "BasicStack(i32, 10)   (stack size of 10)" {
    var expecting:[]const i32 = undefined;

    var buf = [_]i32{0xaa} ** 10;
    var stack:BasicStack(i32, 10) = try .init(&buf);

    try expect(stack.len() == 0);

    try expectEqlSlices(i32, stack.slice(), &.{});

    expecting = &.{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
    for (expecting) |n| try stack.push(n);
    try expectEqlSlices(i32, stack.slice(), expecting);

    try expectError(error.StackOverflow, stack.push(0));

    for (1..expecting.len+1) |i| {
        const n = expecting[expecting.len-i];
        try expect(n == try stack.pop());
    }
    try expectError(error.StackUnderflow, stack.pop());

    try expectEqlSlices(i32, stack.slice(), &.{});
}
