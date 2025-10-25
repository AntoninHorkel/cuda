const std = @import("std");
const builtin = @import("builtin");
const os = std.os.linux;
const posix = std.posix;

pub const IoCtlError = error{
    FileSystem,
    InterfaceNotFound, // TODO
} || posix.UnexpectedError;

const bits = switch (builtin.cpu.arch) {
    .mips,
    .mipsel,
    .mips64,
    .mips64el,
    .powerpc,
    .powerpcle,
    .powerpc64,
    .powerpc64le,
    .sparc,
    .sparc64,
    => .{
        .size = 13,
        .dir = 3,
        .none = 1,
        .read = 2,
        .write = 4,
    },
    else => .{
        .size = 14,
        .dir = 2,
        .none = 0,
        .read = 2,
        .write = 1,
    },
};

pub const IoCtlDirection = enum(std.meta.Int(.unsigned, bits.dir)) {
    none = bits.none,
    read = bits.read,
    write = bits.write,
};

pub const IoCtlRequest = packed struct {
    nr: u8,
    t: u8,
    size: std.meta.Int(.unsigned, bits.size),
    dir: IoCtlDirection,
};

comptime {
    std.debug.assert(@bitSizeOf(IoCtlRequest) == 32);
}

pub fn ioctl(fd: os.fd_t, request: IoCtlRequest, arg: *anyopaque) IoCtlError!void {
    while (true) {
        switch (posix.errno(os.ioctl(fd, request, @intFromPtr(arg)))) {
            .SUCCESS => return,
            .INVAL => unreachable, // Bad parameters.
            .NOTTY => unreachable,
            .NXIO => unreachable,
            .BADF => unreachable, // Always a race condition.
            .FAULT => unreachable, // Bad pointer parameter.
            .INTR => continue,
            .IO => return error.FileSystem,
            .NODEV => return error.InterfaceNotFound,
            else => |err| return posix.unexpectedErrno(err),
        }
    }
}
