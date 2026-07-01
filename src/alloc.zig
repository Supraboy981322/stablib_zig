const module = @import("module.zig");
const mem = module.mem;
const types = module.types;
const general = module.general;

//purpose of module:
//  Zig removed std.heap.GeneralPurposeAllocator and

//usage of stdlib
//   - the std.mem.Allocator interface is required to use most things in stdlib
//   - std.heap.page_allocator is (for now) being used as a backing allocator
//      - the std.mem.Allocator interface is (clearly) located in the stdlib
//      - std.mem.Allocator.Alignment is required for the stdlib interface
//   - std.Io is required to use a std.Io.Mutex
// TODO: replacing stdlib
//   - the std.mem.Allocator interface is likely never going to be removed (it's used too much in stdlib)
//   - std.Io.Mutex replacement is pending

const std = @import("std");
const Allocator = std.mem.Allocator;
const Alignment = std.mem.Alignment;

const comptimeAssert = general.comptimeAssert;
const comptimeAssertMany = general.comptimeAssertMany;

pub const Error = error { OutOfMemory };

//a very thin wrapper around heap.page_allocator with a mutex

//const back = std.heap.page_allocator; // TODO: I suspect this will be removed
const back =
    if (@import("builtin").mode == .Debug)
        std.testing.allocator //I don't plan on implementing a debug/testing allocator anytime soon
    else
        std.heap.allocator;   //may have to replace this in some way
var mutex:std.Io.Mutex = .init;

pub const interface:Allocator = .{
    .ptr = undefined,
    .vtable = &.{
        .alloc = &internal_alloc,
        .resize = &internal_resize,
        .free = &internal_free,
        .remap = &internal_remap,
    }
};

//never fails
pub fn setup() types.SetupStatus {
    return .ok;
}

fn internal_alloc(
    _:*anyopaque,
    len:usize,
    alignment:Alignment,
    ret_addr:usize
) ?[*]u8 {
    if (module.io) |io| {
        mutex.lock(io) catch return null;
        defer mutex.unlock(io);
        return back.rawAlloc(len, alignment, ret_addr);
    } else
        @panic("allocator was never setup (call global setup function)");
}

fn internal_resize(
    _:*anyopaque,
    memory:[]u8,
    alignment:Alignment,
    new_len:usize,
    ret_addr:usize
) bool {
    if (module.io) |io| {
        mutex.lock(io) catch return true; // TODO: probably should handle this
        defer mutex.unlock(io);
        return back.rawResize(memory, alignment, new_len, ret_addr);
    } else
        @panic("allocator was never setup (call global setup function)");
}

fn internal_free(
    _:*anyopaque,
    memory:[]u8,
    alignment:Alignment,
    ret_addr:usize
) void {
    if (module.io) |io| {
        mutex.lock(io) catch return; // TODO: probably should handle this
        defer mutex.unlock(io);
        return back.rawFree(memory, alignment, ret_addr);
    } else
        @panic("allocator was never setup (call global setup function)");
}

fn internal_remap(
    _:*anyopaque,
    memory:[]u8,
    alignment:Alignment,
    new_len:usize,
    ret_addr:usize
) ?[*]u8 {
    if (module.io) |io| {
        mutex.lock(io) catch return null;
        defer mutex.unlock(io);
        return back.rawRemap(memory, alignment, new_len, ret_addr);
    } else
        @panic("allocator was never setup (call global setup function)");
}

// TODO: alloc wrapper for non-bytes
pub fn alloc(comptime T:type, len:usize) Error![]T {
    comptimeAssert(T == u8, "TODO: alloc wrapper for non-bytes");
    var res = internal_alloc(
        undefined, @sizeOf(T) * len, @alignOf(T), @returnAddress()
    ) orelse {
        return error.OutOfMemory;
    };
    return res[0..len];
}
pub fn free(v:anytype) void {
    const info = @typeInfo(@TypeOf(v));
    comptimeAssertMany(&.{
        info == .pointer,
        info.pointer.size == .slice
    }, "not a slice");
    const bytes:[]u8 = @ptrCast(@constCast(mem.absorbTerminator(v)));
    if (bytes.len == 0) return;
    @memset(bytes, undefined);
    const alignment = info.alignment orelse @alignOf(info.child);
    internal_free(bytes, .fromByteUnits(alignment), @returnAddress());
}
