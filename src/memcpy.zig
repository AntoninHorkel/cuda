const std = @import("std");
const builtin = @import("builtin");
const nvptx = @import("nvptx.zig");

comptime {
    if (builtin.os.tag != .cuda)
        @compileError("CUDA only.");
}

const MEMCPY_BLOCK_SIZE = 256;
const MEMCPY_THREAD_COPYSIZE = 16;
const MAX_GRID_SIZE_X = 65535;
const MEMCPY_HIGHBW_BYTE_GRANULARITY = 4096;
const MEMCPY_FINISH_BYTE_GRANULARITY = 4;

export fn kernelHighBandwidth(dst: *addrspace(.global) u32, src: *const addrspace(.global) u32) callconv(.nvptx_kernel) void {
var index = ((MEMCPY_BLOCK_SIZE * (nvptx.blockIdY() * nvptx.gridDimX() + nvptx.blockIdX())) << 2) + nvptx.threadIdX();
    inline for (0..4) |_| {
        dst[index] = src[index];
        index += MEMCPY_BLOCK_SIZE;
    }
}

export fn kernelLowLatency(dst: *addrspace(.global) u32, src: *const addrspace(.global) u32, n: u32) callconv(.nvptx_kernel) void {
    const index = MEMCPY_BLOCK_SIZE * nvptx.blockIdX() + nvptx.threadIdX();
    if (index < n)
        dst[index] = src[index];
}

export fn kernelTrailing(dst: *addrspace(.global) u32, src: *const addrspace(.global) u32, n: u32) callconv(.nvptx_kernel) void {
    const index = MEMCPY_BLOCK_SIZE * nvptx.blockIdX() + nvptx.threadIdX();
    if (index < n)
        dst[index] = src[index];
}

pub fn memcpy(comptime Type: type, dst: *align(@alignOf(u32)) Type, src: *const align(@alignOf(u32)) Type) !void {
    std.debug.assert(dst.len >= src.len);

    const high_bandwidth = src.len > (1024 * 1024); // 1 MiB

    if (high_bandwidth) {
        // TODO: Launch kernelHighBandwidth
    }

    if (!high_bandwidth or src.len % MEMCPY_HIGHBW_BYTE_GRANULARITY != 0) {
        // TODO: Launch kernelLowLatency
    }

    if (src.len % MEMCPY_FINISH_BYTE_GRANULARITY != 0) {
        // TODO: Launch kernelTrailing
    }
}
