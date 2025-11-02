const std = @import("std");
const posix_fix = @import("posix_fix.zig");
const os = std.os.linux;
const posix = std.posix;

const c = @cImport({
    @cInclude("common/inc/nvtypes.h");
});

inline fn unknownNvStatus(status: c.NvV32) error{Unknown} {
    if (std.posix.unexpected_error_tracing) {
        std.debug.print("Unknown status: {s}\n", .{c.nvstatusToString(status)});
        std.debug.dumpCurrentStackTrace(null);
    }
    return error.Unknown;
}

pub const Driver = struct {};

pub const Device = struct {
    pub const Selector = union(enum) {
        auto: AutoPreference,
        selector: fn () void,

        pub const AutoPreference = enum {
            high_performance,
            low_power,
        };
    };
};
