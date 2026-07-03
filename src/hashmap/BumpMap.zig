const module = @import("../module.zig");

const mem = module.mem;
const meta = module.meta;
const testing = module.testing;

const comptimeAssert = module.comptimeAssert;
const comptimeAssertMany = module.general.comptimeAssertMany;
const assert = module.assert;
const maxInt = module.math.maxInt;
const expect = testing.expect;
const expectMany = testing.expectMany;
const fieldCount = meta.fieldCount;

// - a "map" with a fixed-size table, specifically for enums and ints
// - can provide a bucket size, or null; if null:
//   - either maxInt(K) (when K is an int type) or fieldCount(K) (when K is an enum type)
// - values are ints
// - two primary operations:
//   - bump(key): increase value at key in bucket
//   - knock(key): decrease value at key in bucket
// - intended for tracking the count of something
//   eg: a byte tracker (for the count a specific byte) in an iterator
pub fn BumpMap(comptime K:type, comptime bucket_size:?usize) type {
    const is_enum = @typeInfo(K) == .@"enum";
    const is_int = @typeInfo(K) == .int;
    comptimeAssert(is_int or is_enum, "value must an integer or enum");
    return struct {
        bucket:[size]usize,
        
        const Self = @This();
        pub const size = if (bucket_size) |c| c else if (is_int) maxInt(K) else fieldCount(K)+1;

        pub fn init() Self {
            return .{ .bucket = [_]usize{0} ** size };
        }

        inline fn idx(k:K) usize {
            const i:usize =
                if (is_int)
                    @intCast(k)
                else
                    @intFromEnum(k);
            assert(i < size, "provided key is larger than the bucket (which's illegal)");
            return i;
        }

        pub fn bump(self:*Self, k:K) void {
            self.bucket[idx(k)] += 1;
        }
        pub fn knock(self:*Self, k:K) void {
            self.bucket[idx(k)] -= 1;
        }

        pub fn reset(self:*Self) void {
            self.bucket = [_]usize{0} ** size;
        }

        pub fn get(self:*Self, k:K) usize {
            return self.bucket[idx(k)];
        }
        pub fn set(self:*Self, k:K, v:usize) void {
            self.bucket[idx(k)] = v;
        }

        pub fn bumpN(self:*Self, k:K, amnt:usize) void {
            self.bucket[idx(k)] += amnt;
        }
        pub fn knockN(self:*Self, k:K, amnt:usize) void {
            self.bucket[idx(k)] -= amnt;
        }

        //could be useful for having another thread lock until value changes
        pub fn getPtr(self:*Self, k:K) *usize {
            return @ptrCast(self.bucket[idx(k)..].ptr);
        }
    };
}



pub const ByteBumpMap = BumpMap(u8, null);

test ByteBumpMap {
    var map:ByteBumpMap = .init();
    for (map.bucket) |slot| try expect(slot == 0);

    map.bump('a');
    try expectMany(&.{
        map.bucket['a'] == 1,
        map.get('a') == 1,
    });
    for (map.bucket[0..'a']) |slot| try expect(slot == 0);
    for (map.bucket['a'+1..]) |slot| try expect(slot == 0);

    map.reset();
    for (map.bucket) |slot| try expect(slot == 0);

    map.bump(2);

    var second:ByteBumpMap = .init();
    try expect(second.get(2) == 0);
}

test BumpMap {
    const K = enum{ foo, bar, baz };
    var map:BumpMap(K, null) = .init();
    for (map.bucket) |slot| try expect(slot == 0);

    map.bump(.foo);
    try expect(map.get(.foo) == 1);
    for (map.bucket[1..]) |slot| try expect(slot == 0);

    map.knock(.foo);
    for (map.bucket) |slot| try expect(slot == 0);

    map.getPtr(.baz).* = 1;
    try expect(map.get(.baz) == 1);
}
