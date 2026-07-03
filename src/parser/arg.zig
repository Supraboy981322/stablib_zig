const module = @import("../module.zig");
const builtin = @import("builtin");


// TODO:
//  - think about it longer, restart when you have a better interface

const Type = module.types.builtin.Type;
const TypeEnum = module.types.builtin.TypeEnum;
const fmt = module.fmt;


pub const ArgMap = []const struct{ []const u8, type };

pub fn Parser(comptime map:ArgMap) type {
    return struct {
        args:[]const []const u8 = &.{},
        mapped:[]const MapValue,

        pub const MapValue = struct{ u8, TypeEnum, ?*anyopaque };
        pub const MappedArgs = blk: {
            var Map:[map.len]type = undefined;
            for (map, 0..) |slot, i| {
                if (!module.meetsMinimumVersion()) {
                    //@compileError("don't blame me for Zig removing builtins and leaving no way to easily use old ones conditionally");
                    ////const T = struct{ []const u8, ?slot[1] };
                    ////const tuple:Type.Struct = .{ .Struct = .{
                    ////    .layout = .auto,
                    ////    .fields = &.{
                    ////        .{
                    ////            .name = "0",
                    ////            .type = []const u8,
                    ////            .default_value = null,
                    ////            .is_comptime = false,
                    ////            .alignment = @alignOf([]const u8),
                    ////        },
                    ////        .{
                    ////            .name = "1",
                    ////            .type = @TypeOf(slot[1]),
                    ////            .default_value = null,
                    ////            .is_comptime = false,
                    ////            .alignment = @alignOf(?@TypeOf(slot[1])),
                    ////        },
                    ////    },
                    ////    .decls = &.{},
                    ////    .is_tuple = true,
                    ////} };
                    ////Map[i] = @Type(tuple);
                } else
                    Map[i] = @Tuple(&.{ []const u8, ?slot[1] });
            }

            break :blk @TypeOf(Map);
        };

        const Self = @This();

        pub fn init() Self {
            return .{};
        }
        pub fn deinit(self:*Self) void {
            for (self.args) |arg| switch (arg[1]) {

            };
        }

        pub fn do(self:*Self, args:[]const []const u8) !MappedArgs {
            _ = .{ self, args };
            @breakpoint();
        }
    };
}
