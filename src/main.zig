const std = @import("std");
const builtin = @import("builtin");
const posix_fix = @import("posix_fix.zig");
const os = std.os.linux;
const posix = std.posix;

const c = @cImport({
    @cInclude("common/inc/nvtypes.h");
});

const tracy = @import("tracy.zig");

comptime {
    if (builtin.os.tag != .linux)
        @compileError("Linux only.");
}

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

pub fn main() !void {
    var stack_fallback = std.heap.stackFallback(100_000, std.heap.smp_allocator); // TODO: Sane size (10KB for now)
    const allocator = stack_fallback.get();

    var cubin_parse_buffer: [4096]u8 = undefined;
    // std.mem.span(std.os.argv[0])
    var cubin: @import("cubin.zig").Cubin = try .parseFilePath("tests/write_float_shared_mem.cubin", &cubin_parse_buffer, allocator, .{ .mmap = true });
    defer cubin.deinit(allocator);
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
