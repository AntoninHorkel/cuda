const builtin = @import("builtin");
const nvptx = @import("../src/nvptx.zig");

comptime {
    if (builtin.target.cpu.arch != .nvptx or builtin.target.cpu.arch != .nvptx64)
        @compileError("NVPTX only.");
    if (builtin.os.tag != .cuda)
        @compileError("CUDA only.");
}

export fn kernelForward(
    comptime Type: type,
    comptime N: usize,
    // B: u32,
    T: u32,
    C: u32,
    H: u32,
    _r: *addrspace(.global) const Type,
    _w: *addrspace(.global) const Type,
    _k: *addrspace(.global) const Type,
    _v: *addrspace(.global) const Type,
    _a: *addrspace(.global) const Type,
    _b: *addrspace(.global) const Type,
    _y: *addrspace(.global) Type,
) callconv(.nvptx_kernel) void {
    const e = nvptx.blockIdX() / H;
    const h = nvptx.blockIdX() % H;
    const i = nvptx.threadIdx();

    var state: [N]f32 = @splat(0);
    var r: [N]f32 = undefined;
    var k: [N]f32 = undefined;
    var w: [N]f32 = undefined;
    var a: [N]f32 = undefined;
    var b: [N]f32 = undefined;

    for (0..T) |_t| {
        const t = e * T * C + h * N + i + _t * C;
        nvptx.syncThreads();
        r[i] = @as(f32, _r[t]);
        w[i] = @exp(-@exp(@as(f32, _w[t])));
        k[i] = @as(f32, _k[t]);
        a[i] = @as(f32, _a[t]);
        b[i] = @as(f32, _b[t]);
        nvptx.syncThreads();
        var sa = 0.0;
        inline for (0..N) |j|
            sa += a[j] * state[j];
        const vv = @as(f32, _v[t]);
        var y = 0.0;
        inline for (0..N) |j| {
            state[j] = state[j] * w[j] + k[j] * vv + sa * b[j];
            y += state[j] * r[j];
        }
        _y[t] = @as(Type, y);
    }
}
