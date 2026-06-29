//usage of stdlib
//  - DupeOpts contains an optional field to dupe a HashMap using an
//    stdlib allocator

// TODO

const types = @import("types.zig");

const allocator = @import("alloc.zig");
const alloc = allocator.allocator;

pub fn HashMap(comptime Key:type, comptime Val:type) type {
    _ = .{ Key, Val };
    return struct {
        bucket:[]Entry,
        size:usize,
        hash_num:usize = 5381,

        pub const Entry = struct {
            key:Key,
            val:Val,
            next:?*Entry,
        };

        const Self = @This();

        pub fn PutError(opts:PutOpts) type {
            var Res = allocator.Error;
            if (opts.no_clobber) Res = Res || error{ Clobber };
            return Res;
        }

        pub const DupeOpts = struct {
            allocator:?@import("std").mem.Allocator = null,
        };

        pub const GetOpts = struct {
            ptr:bool = false,

            pub fn RetType(self:GetOpts) type {
                return if (self.ptr) *Val else Val;
            }
        };
        pub const PutOpts = struct {
            no_clobber:bool = true,
        };
        pub fn GetOrPutPtrResult(opts:GetOpts) type {
            return union(enum) {
                get:opts.RetType,
                put:*Val,
            };
        }

        pub fn put(self:*Self, k:Key, v:Val, comptime opts:PutOpts) PutError(opts)!void {
            _ = v;
            if (self.get(k, .{ .ptr = true })) |existing| {
                if (opts.no_clobber) return error.Clobber;
                _ = existing;
                //return;
            }
            if (self.contains(k)) return error.Clobber;
            @compileError("TODO: HashMap.putClobber()");
        }

        pub fn get(self:*Self, k:Key, comptime opts:GetOpts) ?opts.RetType() {
            _ = .{ self };
            const key = self.hash(k);
            _ = key;
            @compileError("TODO: HashMap.get()");
        }

        pub fn contains(self:*Self, k:Key) bool {
            _ = .{ self };
            const idx = self.hash(k);
            _ = idx;
            @compileError("TODO: HashMap.contains()");
        }

        pub fn getOrPut(self:*Self, k:Key, put_v:Val, comptime opts:GetOpts) ?opts.RetType() {
            const ret = self.getOrPutPtr(k, opts);
            switch (ret) {
                .get => |v| return v,
                .put => |v| v.* = put_v,
            }
            return null;
        }
        pub fn getOrPutPtr(self:*Self, k:Key, comptime opts:GetOpts) GetOrPutPtrResult(opts) {
            _ = .{ self };
            const idx = self.hash(k);
            _ = idx;
            @compileError("TODO: HashMap.getOrPutPtr()");
        }
        
        pub fn dupe(self:*Self, k:Key, opts:DupeOpts) allocator.Error!Self {
            _ = .{ self, k, opts };
            @compileError("TODO: HashMap.dupe()");
        }

        pub fn rehash(self:*Self) void {
            _ = self;
            @compileError("TODO: HashMap.rehash()");
        }
        pub fn hash(self:*Self, k:Key) usize {
            _ = .{ self, k };
            //var res = self.hash_num;
            //return res;
            @compileError("TODO: HashMap.hash()");
        }
    };
}
