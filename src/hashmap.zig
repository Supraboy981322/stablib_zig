//usage of stdlib
//  - DupeOpts contains an optional field to dupe a HashMap using an
//    stdlib allocator

const module = @import("module.zig");
const types = module.types;
const meta = module.meta;
const mem = module.mem;

const allocator = module.alloc;
const alloc = allocator.interface;
const todo = module.todo;
const expectMany = module.testing.expectMany;
const expectError = module.testing.expectError;

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
            todo("HashMap.putClobber()", .compiling);
        }

        pub fn get(self:*Self, k:Key, comptime opts:GetOpts) ?opts.RetType() {
            _ = .{ self };
            const key = self.hash(k);
            _ = key;
            todo("HashMap.get()", .compiling);
        }

        pub fn contains(self:*Self, k:Key) bool {
            _ = .{ self };
            const idx = self.hash(k);
            _ = idx;
            todo("HashMap.contains()", .compiling);
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
            todo("HashMap.getOrPutPtr()", .compiling);
        }
        
        pub fn dupe(self:*Self, k:Key, opts:DupeOpts) allocator.Error!Self {
            _ = .{ self, k, opts };
            todo("HashMap.dupe()", .compiling);
        }

        pub fn rehash(self:*Self) void {
            _ = self;
            todo("HashMap.rehash()", .compiling);
        }
        pub fn hash(self:*Self, k:Key) usize {
            _ = .{ self, k };
            //var res = self.hash_num;
            //return res;
            todo("HashMap.hash()", .compiling);
        }
    };
}

pub fn EnumMap(comptime Enum:type, comptime Val:type) type {
    return struct {
        // TODO:
        //  - should this be an optional pointer to a value?
        bucket:[bucket_size]Value = [_]Value{undefined} ** bucket_size,

        pub const Value = struct {
            available:bool = true,
            value:*Val,
            pub fn init() !Value {
                return .{ .value = try alloc.create(Val) };
            }
            pub fn deinit(self:*Value) void {
                self.available = false;
                alloc.destroy(self.value);
            }
        };

        const Self = @This();
        pub const bucket_size = meta.fieldCount(Enum);

        pub fn init() !Self {
            var res:Self = .{};
            for (&res.bucket) |*slot| slot.* = try .init();
            return res;
        }
        pub fn deinit(self:*Self) void {
            for (&self.bucket) |*slot| slot.deinit();
        }

        inline fn getRaw(self:*Self, key:Enum) *Value {
            return @ptrCast(self.bucket[@intFromEnum(key)..].ptr);
        }

        fn getOrNull(self:*Self, key:Enum) ?*Val {
            const slot = self.bucket[@intFromEnum(key)];
            if (slot.available) return null;
            return slot.value;
        }

        pub fn contains(self:*Self, key:Enum) bool {
            return !self.getRaw(key).available;
        }


        pub const GetOpts = struct {
            ptr:bool = false,
            err_if_missing:bool = false,
        };
        pub fn GetRet(comptime opts:GetOpts) type {
            const V = if (opts.ptr) *Val else Val;
            return
                if (opts.err_if_missing)
                    error{ Missing }!V
                else
                    ?V;
        }
        pub fn get(self:*Self, key:Enum, comptime opts:GetOpts) GetRet(opts) {
            const raw = self.getRaw(key);
            if (raw.available)
                return if (comptime opts.err_if_missing)
                    error.Missing
                else
                    null;
            const v = raw.value;
            return if (comptime opts.ptr) v else v.*;
        }


        pub const PutOpts = struct {
            no_clobber:bool = false,
        };
        pub fn PutRet(comptime opts:PutOpts) type {
            if (opts.no_clobber) return error{ Clobber }!void;
            return void;
        }
        pub fn put(self:*Self, key:Enum, val:Val, comptime opts:PutOpts) PutRet(opts) {
            const slot = self.getRaw(key);
            if (comptime opts.no_clobber)
                if (!slot.available)
                    return error.Clobber;
            defer slot.available = false;
            slot.value.* = val;
        }

        pub const GetOrPutOpts = struct {
            put_how:PutHow = .ptr,
            get_ptr:bool = false,
            get_anyhow:bool = true,

            pub const PutHow = union(enum(u1)) {
                ptr,
                value:Val,
                pub fn val(v:Val) PutHow {
                    return .{ .value = v };
                }
            };
            pub fn verify(self:GetOrPutOpts) void {
                if (self.ptr) self.val == null;
            }
            pub fn ptr() GetOrPutOpts {
                return .{ .put_how = .ptr };
            }
        };
        pub fn GetOrPutRet(comptime opts:GetOrPutOpts) type {
            const Get = if (opts.get_ptr) *Val else Val;
            return switch (opts.put_how) {
                .ptr => union(enum(u1)) {
                    put:*Val,
                    get:Get,
                },
                .value =>
                    if (opts.get_anyhow)
                        struct {
                            inserted:bool,
                            val:Get,
                        }
                    else
                        ?Get,
            };
        }
        fn getOrPut_exists(comptime opts:GetOrPutOpts, v:*Val) GetOrPutOpts(opts) {
            const val = if (opts.get_ptr) v else v.*;
            return switch (comptime opts.put_how) {
                .ptr => .{ .get = val },
                .value =>
                    if (opts.get_anyhow) .{ 
                        .inserted = false,
                        .val = val,
                    } else
                        val
            };
        }
        pub fn getOrPut(self:*Self, key:Enum, comptime opts:GetOrPutOpts) GetOrPutRet(opts) {
            if (!self.get(key, .{
                .ptr = comptime opts.get_ptr
            })) |v|
                return getOrPut_exists(opts, v);

            switch (comptime opts.put_how) {
                .ptr => {
                    self.put(key, undefined, .{ .no_clobber = true }) catch unreachable;
                    return .{ .put = self.get(key, .{ .ptr = true }).? };
                },
                .value => |v| {
                    self.put(key, v, .{ .no_clobber = true }) catch unreachable;
                    return
                        if (comptime opts.get_anyhow) .{
                            .inserted = true,
                            .val = v,
                        } else
                            null;
                },
            }
            unreachable;
        }
    };
}

test "EnumMap(...)" {
    const Foo = enum { a, b, c, d, e, f, g };
    var map:module.types.hashmap.EnumMap(Foo, u8) = try .init();
    defer map.deinit();

    //basic
    try map.put(.a, 102, .{ .no_clobber = true });
    try map.put(.b, 103, .{ .no_clobber = true });
    try expectMany(&.{
        map.get(.a, .{}).? == 102,
        map.get(.a, .{ .ptr = true }).?.* == try map.get(.a, .{ .err_if_missing = true }),

        map.get(.b, .{}).? == 103,
        map.get(.b, .{ .ptr = true }).?.* == try map.get(.b, .{ .err_if_missing = true }),

        map.get(.c, .{}) == null,
    });

    //errors
    try expectError(error.Missing, map.get(.c, .{ .err_if_missing = true }));
    _ = try map.get(.a, .{ .err_if_missing = true });
}
