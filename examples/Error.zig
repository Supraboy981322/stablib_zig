const stablib = @import("stable_lib");
                                                                                     
// TODO: make it actually do something

const DynArr = stablib.DynamicArray(u8);
const Itr = stablib.ByteIterator(.{ .tracking_mode = .string });
const alloc = stablib.allocator;
                                                                                     
//the 'Ok' param can be any type, but here it is 'void' because
//  this example applies the result to a value provided by a pointer
//    (not a very good example, I know)
const ParseResult = stablib.Error(ParseError, void); 
                                                                                     
const ParseError = struct {
    err:Err,
    position:usize,
    line_number:usize,
    src_line:[]const u8,
    buffer_snapshot:[]u8,
  
    pub const Err = error {
        UnexpectedEOF,
        MisplacedSymbol,
        UnexpectedByte,
    };

    //can return error.OutOfMemory
    pub fn mk(state:*State, err:Err) !ParseError {
        return .{
            .line_number = state.itr.counted("\n") + 1,
            .err = err,
            .position = state.itr.pos,
            .buffer_snapshot = try state.buf.string(),
            .src_line = blk: {
                var itr = state.itr;
                var res:DynArr = .init(0, .{});
                defer res.deinit();
                                                                                     
                const line_start = itr.last_seen("\n") orelse 0;
                itr.rewind(line_start);
                                                                                     
                const line = try (itr.collect(.delim("\n")) orelse itr.remaining());
                defer alloc.free(line);
                const line_number = itr.counted("\n");
                                                                                     
                try res.print("{d} | {s}", .{line_number, line});
                break :blk try res.solidify(.{});
            },
        };
    }
};
                                                                                     
const State = struct {
    buf:DynArr,
    itr:Itr,
                                                                                     
    pub fn init(src:[]const u8) State {
        return .{
            .itr = .init(src, .{ .track = &.{ "\n" } }),
            .buf = .init(0, .{}) catch unreachable,
        };
    }
};

pub const Data = struct {
};

fn parse(src:[]const u8, data:*Data) error{OutOfMemory}!ParseResult {
    var state:State = .init(src);
    defer state.deinit();
    
    _ = data;
                                                                                     
    while (state.itr.next()) |b| {
        switch (b) {
            //doesn't really matter what happens here
            else => return .fail(try .mk(&state, error.UnexpectedByte)),
        }
    }
                                                                                     
    return .ok({});
}
