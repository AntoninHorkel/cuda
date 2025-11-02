const builtin = @import("builtin");

comptime {
    if (builtin.target.cpu.arch != .nvptx or builtin.target.cpu.arch != .nvptx64)
        @compileError("NVPTX only.");
    if (builtin.os.tag != .cuda)
        @compileError("CUDA only.");

    @compileError("TODO: Fix this first!!!");
}

// extern fn @"llvm.nvvm.barrier0"() void;
// pub const syncThreads = @"llvm.nvvm.barrier0";
pub inline fn syncThreads() void {
    asm volatile ("bar.sync 0;");
}

pub inline fn threadIdX() usize {
    return @workItemId(0);
}

pub inline fn threadIdY() usize {
    return @workItemId(1);
}

pub inline fn threadIdZ() usize {
    return @workItemId(2);
}

// TODO
// pub inline fn threadDimX() usize {
//     return @intCast(@"llvm.nvvm.read.ptx.sreg.ntid.x"());
// }
// extern fn @"llvm.nvvm.read.ptx.sreg.ntid.x"() i32;

pub inline fn blockIdX() usize {
    return @workItemId(0);
}

pub inline fn blockDimX() usize {
    return @workGroupSize(0);
}

pub inline fn gridDimX() usize {
    const nctaid = asm volatile ("mov.u32 %[r], %nctaid.x;"
        : [r] "=r" (-> u32),
    );
    return @as(usize, nctaid);
}

pub inline fn blockDimY() usize {
    return @workGroupSize(1);
}

pub inline fn blockIdY() usize {
    return @workItemId(1);
}

pub inline fn threadDimY() usize {
    const ntid = asm volatile ("mov.u32 %[r], %ntid.y;"
        : [r] "=r" (-> u32),
    );
    return @intCast(ntid);
}
pub inline fn threadDimZ() usize {
    const ntid = asm volatile ("mov.u32 %[r], %ntid.z;"
        : [r] "=r" (-> u32),
    );
    return @intCast(ntid);
}

pub inline fn gridIdY() usize {
    const ctaid = asm volatile ("mov.u32 %[r], %ctaid.y;"
        : [r] "=r" (-> u32),
    );
    return @intCast(ctaid);
}

pub inline fn gridIdZ() usize {
    const ctaid = asm volatile ("mov.u32 %[r], %ctaid.z;"
        : [r] "=r" (-> u32),
    );
    return @intCast(ctaid);
}

pub inline fn gridDimY() usize {
    const nctaid = asm volatile ("mov.u32 %[r], %nctaid.y;"
        : [r] "=r" (-> u32),
    );
    return @intCast(nctaid);
}

pub inline fn gridDimZ() usize {
    const nctaid = asm volatile ("mov.u32 %[r], %nctaid.z;"
        : [r] "=r" (-> u32),
    );
    return @intCast(nctaid);
}
