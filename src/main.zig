const std = @import("std");
const builtin = @import("builtin");
const lib = @import("lib.zig"); // TODO: Do the work in build.zig
const tracy = @import("tracy.zig");

comptime {
    if (builtin.os.tag != .linux)
        @compileError("Linux only.");
}

pub fn main() !void {
    var stack_fallback = std.heap.stackFallback(100_000, std.heap.smp_allocator); // TODO: Sane size (10KB for now)
    const allocator = stack_fallback.get();

    // var cubin_parse_buffer: [4096]u8 = undefined;
    // std.mem.span(std.os.argv[0])
    var cubin: @import("cubin.zig").Cubin = try .parseFilePath("tests/write_float_shared_mem.cubin", null, allocator, .{ .mmap = true });
    defer cubin.deinit(allocator);
    std.debug.print("\n\n{any}\n", .{cubin.function_map});
}

test {
    std.testing.refAllDeclsRecursive(@This());
}
