const module = @import("module.zig");
const mem = module.mem;
const types = module.types;

const io = module.io;

fn print(comptime msg:[]const u8, args:anytype) void {
    io.print(.err, msg, args) catch {};
}

const Matrix = types.Matrix;

pub inline fn expect(passed:bool) !void {
    if (!passed) return error.TestFailed;
}
pub fn expectMany(pass_conditions:[]const bool) !void {
    for (pass_conditions, 0..) |success, i| expect(success) catch |e| {
        print("condition #{d} failed\n",.{i});
        return e;
    };
}

pub fn expectEqlSlices(comptime T:type, one:[]const T, two:[]const T) !void {
    try expect(mem.eql(T, one, two));
}
pub fn expectEqlMatrices(comptime T:type, one:Matrix(T), two:Matrix(T)) !void {
    try expect(one.len == two.len);
    for (0..one.len) |i| try expectEqlSlices(T, one[i], two[i]);
}
pub fn expectManyEqlSlices(comptime T:type, slices:Matrix(T)) !void {
    try expect(mem.manyEql(T, slices));
}

pub fn expectError(err:anyerror, result:anytype) !void {
    if (result) |_|
        print("expected error, but succeeded", .{})
    else |e| {
        if (e == err) return;
        print("expected error.{t}, but got error.{t}", .{err, e});
    }
    return error.Failed;
}
