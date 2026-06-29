const HashMap = @import("types.zig").HashMap;

pub const ByteOpts = struct {
    tracking_mode:?TrackingMode = null,

    pub const TrackingMode = enum {
        string, byte,
        // TODO: glob (maybe regex too) 

        pub fn T(self:TrackingMode) type {
            switch (self) {
                .string => []const u8,
                .byte => u8,
            }
        }
    };
};
pub fn ByteIterator(comptime type_opts:ByteOpts) type {
    return struct {
        pos:usize = 0,
        current:?u8 = null,
        bytes:[]const u8,

        tracker:if (do_tracking) Tracker.Map else void = if (do_tracking) .empty else {},
        am_tracking:bool,

        const do_tracking = type_opts.tracking_mode != null;

        const Tracker = struct {
            const Map = if (do_tracking) HashMap(Item, usize) else void;
            const Item = if (type_opts.tracking_mode) |m| m.T() else void;
            const Entry = struct {
                times_seen:usize = 0,
                last_seen:usize = 0,

                // NOTE: from last seen, when itr_pos > last_seen, negative, otherwise positive
                //   meaning: (if last_seen is 1)
                //      get_offset(3) would return -2
                //  (so you would add the offset to go to it)
                pub fn get_offset(self:*Entry, itr_pos:usize) isize {
                    return self.last_seen - itr_pos;
                }
            };
        };

        pub const Opts = struct {
            // NOTE: to use this, you must set tracking_mode in the ByteOpts struct passed to ByteIterator
            track:if (do_tracking) ?[]const Tracker.Item else void = if (do_tracking) null else {},
        };

        const Self = @This();

        pub fn init(bytes:[]const u8, opts:Opts) !Self {
            return .{
                .bytes = bytes,
                .am_tracking = if (do_tracking) opts.track != null else false,
                .tracker = if (!do_tracking) {} else blk: {
                    var res:Tracker.Map = .empty;
                    if (opts.track == null) break :blk res;
                    for (opts.track) |thing| try res.put(thing, 0);
                },
            };
        }

        pub fn next(self:*Self) ?u8 {
            if (self.bytes.len <= self.pos + 1) return null;
            self.pos += 1;
            self.current = self.bytes[self.pos];
            if (self.am_tracking) self.tick_tracker();
            return self.current;
        }

        pub fn tick_tracker(self:*Self) void {
            if (!self.am_tracking) return; //in case it's called externally
            switch (comptime type_opts.tracking_mode) {
                .string => unreachable, // TODO: string matching
                .byte => if (self.tracker.getPtr(self.current)) |b| {
                },
            }
        }
    };
}
