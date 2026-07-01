const module = @import("module.zig");
const mem = module.mem;
const types = module.types;

// TODO:
//  - print (see... somewhere it's around here, I have full notes on it somewhere)
const print = @import("std").debug.print;

const Matrix = types.Matrix;

pub inline fn expect(passed:bool) !void {
    if (!passed) return error.TestFailed;
}
pub fn expectMany(pass_conditions:[]const bool) !void {
    for (pass_conditions) |success| try expect(success);
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
