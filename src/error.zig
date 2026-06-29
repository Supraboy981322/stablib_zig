//no stdlib

//a small helper intended to be used in a thin wrapper
//  to return actual information with an error
//    see 'intended usage' below
pub fn Error(Err:type, Ok:type) type {
    return union(bool) {
        err:Err,
        ok:Ok,

        pub fn fail(info:Err) @This() {
            return .{ .err = info };
        }
        pub fn okay(result:Ok) @This() {
            return .{ .ok = result };
        }
    };
}

//intended usage (example)
//
//  const stablib = @import("stable_lib");
//
//  const DynArr = stablib.DynamicArray(u8);
//  const Itr = stablib.ByteIterator(.{ .tracking_mode = .string });
//  const alloc = stablib.allocator;
//
//  //the 'Ok' param can be any type, but here it is 'void' because
//  //  this example applies the result to a value provided by a pointer
//  //    (not a very good example, I know)
//  const ParseResult = Error(ParseError, void); 
//
//  const ParseError = struct {
//      err:Err,
//      position:usize,
//      line_number:usize,
//      src_line:[]const u8,
//      buffer_snapshot:[]u8,
//    
//      pub const Err = error {
//          UnexpectedEOF,
//          MisplacedSymbol,
//          UnexpectedByte,
//      };
//  
//      //can return error.OutOfMemory
//      pub fn mk(state:*State, err:Err) !ParseError {
//          return .{
//              .line_number = state.itr.counted("\n") + 1,
//              .err = err,
//              .position = state.itr.pos,
//              .buffer_snapshot = try state.buf.soldify(.{}),
//              .src_line = blk: {
//                  var itr = state.itr;
//                  var res:DynArr = .init(0, .{});
//                  defer res.deinit();
//
//                  const line_start = itr.last_seen("\n") orelse 0;
//                  itr.rewind(line_start);
//
//                  const line = try (itr.collect(.delim("\n")) orelse itr.remaining());
//                  defer alloc.free(line);
//                  const line_number = itr.counted("\n");
//
//                  try res.print("{d} | {s}", .{line_number, line});
//                  break :blk try res.solidify(.{});
//              },
//          };
//      }
//  };
//
//  const State = struct {
//      buf:DynArr,
//      itr:Itr,
//
//      pub fn init(src:[]const u8) State {
//          return .{
//              .itr = .init(src, .{ .track = &.{ "\n" } }),
//              .buf = .init(0, .{}),
//          };
//      }
//  };
//
//  fn parse(src:[]const u8, data:*Data) error{OutOfMemory}!ParseResult {
//      var state:State = .init(src);
//      defer state.deinit();
//
//      while (state.itr.next()) |b| {
//          switch (b) {
//              //doesn't really matter what happens here
//              else => return .fail(try .mk(&state, error.UnexpectedByte)),
//          }
//      }
//
//      return .ok({});
//  }
