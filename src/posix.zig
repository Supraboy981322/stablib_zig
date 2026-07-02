//usage of stdlib
//  - 'std.os'; very low level, breaks everything if changed
//      so likely won't change too often (I hope)
//      - required for syscalls
const os = @import("std").os;
const linux = os.linux;

const builtin = @import("builtin");
const module = @import("module.zig");

const testing = module.testing;
const general = module.general;
const sys = module.sys;
const fmt = module.fmt;

const expect = testing.expect;
const isWordSize = sys.isWordSize;
const expectEqlSlices = testing.expectEqlSlices;
const assert = general.assert;
const todo = module.todo;

// TODO:
//  - error types
//  - everything that isn't Linux

pub const posix = switch (builtin.target.os.tag) {
    .linux => struct {
        pub const fd_t = i32;
        pub const Fd = enum(fd_t) {
            in = 0,  //stdin
            out = 1, //stdout
            err = 2, //stderr
            _,
            pub fn fd(num:fd_t) Fd {
                return @enumFromInt(num);
            }
            pub fn value(self:Fd) fd_t {
                return @intFromEnum(self);
            }
        };

        pub const O = linux.O;
        pub const mode_t = linux.mode_t;

        pub const PATH_MAX = linux.PATH_MAX;

        pub fn toPosixPath(path:[]const u8) error{PathTooLong}![PATH_MAX-1:0]u8 {
            return fmt.toSentinel(path, .nul, PATH_MAX) catch {
                return error.PathTooLong;
            };
        }


        //For now, this is a thin wrapper around writeAll with an enum for fd_t
        pub fn print(where:Fd, msg:[]const u8) !void {
            try writeAll(@intFromEnum(where), msg);
        }


        pub fn writeAll(fd:fd_t, msg:[]const u8) !void {
            var written:usize = 0;
            while (written < msg.len) {
                const n = try write(fd, msg[written..]);
                written += n;
                @import("std").debug.print("wrote: {d} (total:{d})\n", .{n, written});
            }
            try fsync(fd);
        }
        pub fn write(fd:fd_t, msg:[]const u8) !usize {
            while (true) {
                return writeRaw(fd, @constCast(msg.ptr), msg.len) catch |e| {
                    if (e == error.Interrupted) continue;
                    return e;
                };
            }
        }
        pub fn writeRaw(fd:fd_t, ptr:[*]u8, len:usize) !usize {
            const rc = linux.write(fd, ptr, len);
            if (zigSysErr(rc)) |err| return err;
            return @intCast(rc);
        }
        pub fn fsync(fd:fd_t) !void {
            const rc = linux.fsync(fd);
            if (zigSysErr(rc)) |err| return switch (err) {
                error.NoSpaceLeft, error.IoError => |e| e,
                error.ExceededQuota => error.DiskQuota,
                error.BadFileDescriptor, error.InvalidArgument, error.ReadOnlyFS => unreachable,
                else => error.Unexpected,
            };
        }


        // TODO:
        //  - readAlloc(fd:fd_t) to read entire file
        pub fn read(fd:fd_t, buf:[]u8, amnt:usize) !usize {
            assert(buf.len >= amnt, "buffer too small");
            while (true) {
                const n = readRaw(fd, buf.ptr, amnt) catch |e| {
                    if (e == error.Interrupted) continue;
                    return e;
                };
                return n;
            }
        }
        pub fn readRaw(fd:fd_t, buf:[*]u8, amnt:usize) !usize {
            const rc = linux.read(fd, buf, amnt);
            if (zigSysErr(rc)) |err| return err;
            return @intCast(rc);
        }


        pub const PipeErr = error {
            ProcessFdQuotaExceeded,
            SystemFdQuotaExceeded,
            UnexpectedError,
        };
        pub fn pipe() PipeErr![2]fd_t {
            var p:[2]fd_t = undefined;
            if (pipeRaw(&p)) |err| return switch (err) {
                error.InvalidArgument => unreachable, //invalid pipe() params
                error.BadAddress => unreachable, //pointer to fd pair is invalid
                error.FileTableOverflow => error.SystemFdQuotaExceeded,
                error.TooManyOpenFiles => error.ProcessFdQuotaExceeded,
                else => return error.UnexpectedError,
            };
            return p;
        }
        pub fn pipeRaw(fd_buf:*[2]fd_t) !void {
            const rc = linux.pipe(fd_buf);
            return zigSysErr(rc) orelse {};
        }


        pub fn open(path:[]const u8, flags:O, perm:mode_t) !void {
            const p = try toPosixPath(path);
            return try openRaw(p, flags, perm);
        }
        pub fn openRaw(path:[*:0]const u8, flags:O, perm:mode_t) !fd_t {
            while (true) {
                const rc = linux.open(path, flags, perm);
                if (zigSysErr(rc)) |err| {
                    if (err == error.Interrupted) continue;
                    return err;
                }
                return @intCast(rc);
            }
        }


        pub fn close(fd:i32) void {
            const rc = linux.close(fd);
            assert(errno(rc) != .BADF, "likely race condition (fd not active)");
        }

        pub fn getLSeekErr(err:anyerror) anyerror {
            return switch (err) {
                error.BadFileDescriptor => unreachable, //fd isn't available (likely a race condition)
                error.InvalidArgument => error.Unseekable,
                error.ValueOverflowsType => error.Unseekable,
                error.IllegalSeek => error.Unseekable,
                error.NotExist => error.Unseekable,
                else => error.Unexpected,
            };
        }
        pub fn lseekGet(fd:fd_t) !u64 {
            if (isWordSize(32)) {
                var pos:u64 = undefined;
                const rc = linux.llseek(fd, 0, &pos, 1);
                if (zigSysErr(rc)) |err| return getLSeekErr(err);
                return pos;
            }

            const rc = linux.lseek(fd, 0, 1);
            if (zigSysErr(rc)) |err| return getLSeekErr(err);
            return @bitCast(rc);
        }
        pub const SeekFrom = enum(usize) {
            start = 0,
            current = 1,
            end = 2,
        };
        pub fn lseek(fd:fd_t, offset:u64, from:SeekFrom) !void {
            if (isWordSize(32)) {
                var res:u64 = undefined;
                const rc = linux.llseek(fd, offset, &res, @intFromEnum(from));
                if (zigSysErr(rc)) |err| return getLSeekErr(err);
                return;
            }
            const rc = linux.lseek(fd, @bitCast(offset), @intFromEnum(from));
            if (zigSysErr(rc)) |err| return getLSeekErr(err);
        }


        pub inline fn syscallOk(rc:usize) bool {
            return errno(rc) == .SUCCESS;
        }
        pub const errno = errnoFromSyscall;
        pub fn errnoFromSyscall(r:usize) linux.E {
            const s: isize = @bitCast(r);
            const i = if (s > -4096 and s < 0) -s else 0;
            return @enumFromInt(i);
        }
        pub const zigSysErr = zigErrorFromSyscall;
        pub inline fn zigErrorFromSyscall(rc:usize) ?anyerror {
            return zigError(errno(rc));
        }


        pub const MkMemFdError = error {
            NameTooLong,
            OutOfMemory,
            ProcessFdQuotaExceeded,
            SystemFdQuotaExceeded,
            UnexpectedError,
        };
        // TODO:
        //  - construct the flags integer from struct
        pub fn mkMemFd(name:[]const u8, flags:u32) MkMemFdError!fd_t {
            const n = toPosixPath(name) catch return error.NameTooLong;
            return try mkMemFdRaw(n[0..].ptr, flags);
        }
        pub fn mkMemFdRaw(name:[*:0]const u8, flags:u32) MkMemFdError!fd_t {
            const rc = linux.memfd_create(name, flags);
            return if (zigSysErr(rc)) |err| switch (err) {
                error.BadAddress => unreachable, //name contains invalid memory
                error.InvalidArgument => error.NameTooLong,
                error.FileTableOverflow => error.SystemFdQuotaExceeded,
                error.TooManyOpenFiles => error.ProcessFdQuotaExceeded,
                error.OutOfMemory => error.OutOfMemory,
                else => error.UnexpectedError,
            } else
                @intCast(rc);
        }



        test "mkMemFd | print > write | read > readN > readRaw" {
            const txt = "foo";
            const fd = try mkMemFd(txt, 0);
            defer close(fd);
            try print(.fd(fd), txt);
            try lseek(fd, 0, .start);
            var buf:[1024]u8 = undefined;
            const n = try read(fd, &buf, txt.len);
            try expect(n == txt.len);
            try expectEqlSlices(u8, buf[0..n], txt);
        }



        pub fn zigError(e:linux.E) ?anyerror {
            return switch (e) {
                .SUCCESS => null,
                .PERM => error.OperationNotPermitted,
                .NOENT => error.FileNotExist,
                .SRCH => error.NoSuchProcess,
                .INTR => error.Interrupted,
                .IO => error.IoError,
                .NXIO => error.NotExist,
                .@"2BIG" => error.ArgsTooLong,
                .NOEXEC => error.ExecFormatError,
                .BADF => error.BadFileDescriptor,
                .CHILD => error.NoChild,
                .AGAIN => error.TryAgainOrWouldBlock,
                .NOMEM => error.OutOfMemory,
                .ACCES => error.PermissionDenied,
                .FAULT => error.BadAddress,
                .NOTBLK => error.BlockDeviceRequired,
                .BUSY => error.ResourceBusy,
                .EXIST => error.FileExists,
                .XDEV => error.CrossDeviceLink,
                .NODEV => error.NoSuchDevice,
                .NOTDIR => error.NotDir,
                .ISDIR => error.IsDir,
                .INVAL => error.InvalidArgument,
                .NFILE => error.FileTableOverflow,
                .MFILE => error.TooManyOpenFiles,
                .NOTTY => error.NotTTY,
                .TXTBSY => error.TextFileBusy,
                .FBIG => error.FileTooBig,
                .NOSPC => error.NoSpaceLeft,
                .SPIPE => error.IllegalSeek,
                .ROFS => error.ReadOnlyFS,
                .MLINK => error.TooManyLinks,
                .PIPE => error.BrokenPipe,
                .DOM => error.MathArgOutOfDomain,
                .RANGE => error.MathResultNotRepresentable,
                .DEADLK => error.WouldDeadlock,
                .NAMETOOLONG => error.FilenameTooLong,
                .NOLCK => error.NoRecordLock,
                .NOSYS => error.NotImplemented,
                .NOTEMPTY => error.DirNotEmpty,
                .LOOP => error.TooManySymbolicLinks,
                .NOMSG => error.NoMsgOfDesiredType,
                .IDRM => error.IdentRemoved,
                .CHRNG => error.ChannelOutOfRange,
                .L2NSYNC => error.L2NotInSync,
                .L3HLT => error.L3halted,
                .L3RST => error.L3reset,
                .LNRNG => error.LinkOutOfRange,
                .UNATCH => error.DriverNotAttached,
                .NOCSI => error.NoAvailableCSI,
                .L2HLT => error.L2halted,
                .BADE => error.InvalidExchange,
                .BADR => error.InvalidRequestDescriptor,
                .XFULL => error.ExchangeFull,
                .NOANO => error.NoAnode,
                .BADRQC => error.BadRequestCode,
                .BADSLT => error.InvalidSlot,
                .BFONT => error.BadFontFileFormat,
                .NOSTR => error.NotAStream,
                .NODATA => error.NoData,
                .TIME => error.TimerExpired,
                .NOSR => error.OutOfStreamsResources,
                .NONET => error.NotOnNetwork,
                .NOPKG => error.PkgNotInstalled,
                .REMOTE => error.ObjectIsRemote,
                .NOLINK => error.LinkSevered,
                .ADV => error.AdvertiseError,
                .SRMNT => error.SrmountError,
                .COMM => error.CommErrorOnSend,
                .PROTO => error.ProtocolError,
                .MULTIHOP => error.MultihopAttempted,
                .DOTDOT => error.RFSspecificError,
                .BADMSG => error.NotADataMsg,
                .OVERFLOW => error.ValueOverflowsType,
                .NOTUNIQ => error.NameNotUnique,
                .BADFD => error.BadFileDescriptorState,
                .REMCHG => error.RemoteAddressChanged,
                .LIBACC => error.NoSharedLibAccess,
                .LIBBAD => error.CorruptedSharedLib,
                .LIBSCN => error.LibSectionCorrupted,
                .LIBMAX => error.TooManySharedLibLinks,
                .LIBEXEC => error.ExecSharedLib,
                .ILSEQ => error.IllegalSequence,
                .RESTART => error.InterruptedShouldRestart,
                .STRPIPE => error.StreamsPipeError,
                .USERS => error.TooManyUsers,
                .NOTSOCK => error.NotSocket,
                .DESTADDRREQ => error.NeedDestAddr,
                .MSGSIZE => error.MsgTooLong,
                .PROTOTYPE => error.WrongProtocol,
                .NOPROTOOPT => error.ProtocolNotAvailable,
                .PROTONOSUPPORT => error.UnsupportedProtocol,
                .SOCKTNOSUPPORT => error.SocketTypeUnsupported,
                .OPNOTSUPP => error.NotSupported,
                .PFNOSUPPORT => error.ProtocolFamilyUnsupported,
                .AFNOSUPPORT => error.AddressFamilyUnsupportedByProtocol,
                .ADDRINUSE => error.AddressTaken,
                .ADDRNOTAVAIL => error.AddressNotAvailable,
                .NETDOWN => error.NetworkDown,
                .NETUNREACH => error.NetworkUnreachable,
                .NETRESET => error.NetworkConnectionReset,
                .CONNABORTED => error.SoftwareAbortedConnection,
                .CONNRESET => error.PeerResetConnection,
                .NOBUFS => error.BufferFull,
                .ISCONN => error.TransportConnected,
                .NOTCONN => error.TransportNotConnected,
                .SHUTDOWN => error.TransportShutdown,
                .TOOMANYREFS => error.TooManyReferences, //can't splice
                .TIMEDOUT => error.ConnectionTimedOut,
                .CONNREFUSED => error.ConnectionRefused,
                .HOSTDOWN => error.HostIsDown,
                .HOSTUNREACH => error.NoRouteToHost,
                .ALREADY => error.AlreadyInProgress,
                .INPROGRESS => error.NowInProgress,
                .STALE => error.StaleNFSfileHandle,
                .UCLEAN => error.UncleanStructure,
                .NOTNAM => error.NotNamedFile,
                .NAVAIL => error.NoSemaphoresAvailable,
                .ISNAM => error.IsNamedType,
                .REMOTEIO => error.RemoteIoError,
                .DQUOT => error.ExceededQuota,
                .NOMEDIUM => error.NoMediumFound,
                .MEDIUMTYPE => error.WrongMediumType,
                .CANCELED => error.Canceled,
                .NOKEY => error.UnavailableKey,
                .KEYEXPIRED => error.ExpiredKey,
                .KEYREVOKED => error.RevokedKey,
                .KEYREJECTED => error.KeyRejected, //by service
                .OWNERDEAD => error.OwnerDied,
                .NOTRECOVERABLE => error.UnrecoverableState,
                .RFKILL => error.RFkill, //not possible (because of RF-kill)
                .HWPOISON => error.MemoryPageHardwareError,
                .NSRNODATA => error.NoDataFromDNS,
                .NSRFORMERR => error.MissformattedQueryClaim, //DNS
                .NSRSERVFAIL => error.ServerFailed, //DNS
                .NSRNOTFOUND => error.DomainNameNotFound,
                .NSRNOTIMP => error.NotImplementByServer, //DNS
                .NSRREFUSED => error.ServerRefusedQuery, //DNS
                .NSRBADQUERY => error.MissformattedQuery, //DNS
                .NSRBADNAME => error.MissformattedDomainName, //DNS
                .NSRBADFAMILY => error.UnsupportedAddressFamily,
                .NSRBADRESP => error.MissformattedDNSreply, //DNS
                .NSRCONNREFUSED => error.ServerConnectionRefused, //DNS
                .NSRTIMEOUT => error.ServerTimeout, //DNS
                .NSROF => error.EndOfFile,
                .NSRFILE => error.ReadFailed,
                .NSRNOMEM => error.OutOfMemory,
                .NSRDESTRUCTION => error.SoftwareTerminatedLookup,
                .NSRQUERYDOMAINTOOLONG, .NSRCNAMELOOP => error.DomainNameTooLong,
                else => error.Unexpected,
            };
        }
    },
    inline else => |t| todo(@tagName(t), .compiling),
};
