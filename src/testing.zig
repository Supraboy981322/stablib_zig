const mem = @import("mem.zig");
const types = @import("types.zig");

const Matrix = types.Matrix;

pub inline fn expect(passed:bool) !void {
    if (!passed) return error.TestFailed;
}
pub fn expectMany(pass_conditions:[]const bool) !void {
    inline for (pass_conditions) |success| try expect(success);
}

pub fn expectEqualSlices(comptime T:type, one:[]const T, two:[]const T) !void {
    try expect(mem.eql(T, one, two));
}
pub fn expectEqualMatrices(comptime T:type, one:Matrix(T), two:Matrix(T)) !void {
    try expect(one.len == two.len);
    for (0..one.len) |i| try expectEqualSlices(T, one[i], two[i]);
}
