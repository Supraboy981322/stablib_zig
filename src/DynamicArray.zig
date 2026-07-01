const module = @import("module.zig");
const alloc = module.alloc.interface; // TODO: replace with wrapper
const general = module.general;
const assert = general.assert;

pub fn DynamicArray(comptime T:type) type {
    return struct {
        slice:[]T,
        len:usize = 0,
        opts:Opts,

        initial_capacity:usize = 0,

        pub const Opts = struct {
            growth_multiplier:f16,
        };

        pub const DynArr = @This();
        
        pub fn init(capacity:usize, opts:Opts) !DynArr {
            assert(opts.growth_multiplier >= 2, "multiplier must grow array");
            return .{
                .slice = try alloc.alloc(T, capacity),
                .opts = opts,
                .initial_capacity = capacity,
            };
        }
        pub fn deinit(self:*DynArr) void {
            alloc.free(self.slice);
        }

        pub fn append(self:*DynArr, v:T) !void {
            if (self.len + 1 >= self.slice.len) {
                const new_len:usize = @intFromFloat(@max(1.0, @as(f16, @floatFromInt(self.len))) * self.opts.growth_multiplier);
                assert(new_len > self.len, "provided multiplier isn't large enough");
                var new = try alloc.alloc(T, new_len);
                for (0..self.slice.len) |i| new[i] = self.slice[i];
                alloc.free(self.slice);
                self.slice = new;
            }
            self.slice[self.len] = v;
            self.len += 1;
        }
        pub fn appendSlice(self:*DynArr, s:[]const T) !void {
            for (s) |v| try self.append(v);
        }

        pub fn pop(self:*DynArr) ?T {
            if (self.len < 1) return null;
            self.len -= 1;
            return self.slice[self.len];
        }

        pub const Shrink = enum(usize) {
            fit = general.maxInt(usize),
            _,
            pub fn amnt(n:usize) Shrink {
                return @enumFromInt(n);
            }
        };
        pub fn shrink(self:*DynArr, size:Shrink) void {
            const s:usize = switch (size) {
                .fit => self.len,
                _ => |i| i,
            };
            alloc.free(self.slice[self.len+s..]);
            self.slice = self.slice[0..self.len+s];
        }

        pub fn reset(self:*DynArr) !void {
            alloc.free(self.slice);
            self.len = 0;
            self.slice = try alloc.alloc(T, self.initial_capacity);
        }

        pub fn string(self:*DynArr) []const T {
            return self.slice[0..self.len];
        }
    };
}
