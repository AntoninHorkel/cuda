const std = @import("std");
const elf = std.elf;
const mem = std.mem;
const posix = std.posix;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const Endian = std.builtin.Endian;
const File = std.fs.File;
const Fnv1a = std.hash.Fnv1a_64;
const Reader = std.Io.Reader;

pub const AbstractReader = union(enum) {
    file_reader: File.Reader,
    buffer_reader: struct {
        buffer: []const u8,
        interface: Reader,
    },

    pub fn initFile(file_reader: File.Reader) @This() {
        return .{ .file_reader = file_reader };
    }

    pub fn initBuffer(buffer: []const u8) @This() {
        return .{ .buffer_reader = .{
            .buffer = buffer,
            .interface = .fixed(buffer),
        } };
    }

    pub fn reader(self: *@This()) *Reader {
        return switch (self.*) {
            .file_reader => |*file_reader| &file_reader.interface,
            .buffer_reader => |*buffer_reader| &buffer_reader.interface,
        };
    }

    pub fn seekTo(self: *@This(), offset: usize) !void {
        switch (self.*) {
            .file_reader => |*file_reader| try file_reader.seekTo(@intCast(offset)),
            .buffer_reader => |*buffer_reader| buffer_reader.interface = .fixed(buffer_reader.buffer[offset..]),
        }
    }
};

// https://github.com/redplait/denvdis/blob/master/test/nv_rend.cc#L189-L306
fn Relocation(comptime ElfType: type) type {
    return enum(switch (ElfType) {
        elf.Elf32 => u8,
        elf.Elf64 => u32,
    }) {
        R_CUDA_NONE,
        R_CUDA_32,
        R_CUDA_64,
        R_CUDA_G32,
        R_CUDA_G64,
        R_CUDA_ABS32_26,
        R_CUDA_TEX_HEADER_INDEX,
        R_CUDA_SAMP_HEADER_INDEX,
        R_CUDA_SURF_HW_DESC,
        R_CUDA_SURF_HW_SW_DESC,
        R_CUDA_ABS32_LO_26,
        R_CUDA_ABS32_HI_26,
        R_CUDA_ABS32_23,
        R_CUDA_ABS32_LO_23,
        R_CUDA_ABS32_HI_23,
        R_CUDA_ABS24_26,
        R_CUDA_ABS24_23,
        R_CUDA_ABS16_26,
        R_CUDA_ABS16_23,
        R_CUDA_TEX_SLOT,
        R_CUDA_SAMP_SLOT,
        R_CUDA_SURF_SLOT,
        R_CUDA_TEX_BINDLESSOFF13_32,
        R_CUDA_TEX_BINDLESSOFF13_47,
        R_CUDA_CONST_FIELD19_28,
        R_CUDA_CONST_FIELD19_23,
        R_CUDA_TEX_SLOT9_49,
        R_CUDA_6_31,
        R_CUDA_2_47,
        R_CUDA_TEX_BINDLESSOFF13_41,
        R_CUDA_TEX_BINDLESSOFF13_45,
        R_CUDA_FUNC_DESC32_23,
        R_CUDA_FUNC_DESC32_LO_23,
        R_CUDA_FUNC_DESC32_HI_23,
        R_CUDA_FUNC_DESC_32,
        R_CUDA_FUNC_DESC_64,
        R_CUDA_CONST_FIELD21_26,
        R_CUDA_QUERY_DESC21_37,
        R_CUDA_CONST_FIELD19_26,
        R_CUDA_CONST_FIELD21_23,
        R_CUDA_PCREL_IMM24_26,
        R_CUDA_PCREL_IMM24_23,
        R_CUDA_ABS32_20,
        R_CUDA_ABS32_LO_20,
        R_CUDA_ABS32_HI_20,
        R_CUDA_ABS24_20,
        R_CUDA_ABS16_20,
        R_CUDA_FUNC_DESC32_20,
        R_CUDA_FUNC_DESC32_LO_20,
        R_CUDA_FUNC_DESC32_HI_20,
        R_CUDA_CONST_FIELD19_20,
        R_CUDA_BINDLESSOFF13_36,
        R_CUDA_SURF_HEADER_INDEX,
        R_CUDA_INSTRUCTION64,
        R_CUDA_CONST_FIELD21_20,
        R_CUDA_ABS32_32,
        R_CUDA_ABS32_LO_32,
        R_CUDA_ABS32_HI_32,
        R_CUDA_ABS47_34,
        R_CUDA_ABS16_32,
        R_CUDA_ABS24_32,
        R_CUDA_FUNC_DESC32_32,
        R_CUDA_FUNC_DESC32_LO_32,
        R_CUDA_FUNC_DESC32_HI_32,
        R_CUDA_CONST_FIELD19_40,
        R_CUDA_BINDLESSOFF14_40,
        R_CUDA_CONST_FIELD21_38,
        R_CUDA_INSTRUCTION128,
        R_CUDA_YIELD_OPCODE9_0,
        R_CUDA_YIELD_CLEAR_PRED4_87,
        R_CUDA_32_LO,
        R_CUDA_32_HI,
        R_CUDA_UNUSED_CLEAR32,
        R_CUDA_UNUSED_CLEAR64,
        R_CUDA_ABS24_40,
        R_CUDA_ABS55_16_34,
        R_CUDA_8_0,
        R_CUDA_8_8,
        R_CUDA_8_16,
        R_CUDA_8_24,
        R_CUDA_8_32,
        R_CUDA_8_40,
        R_CUDA_8_48,
        R_CUDA_8_56,
        R_CUDA_G8_0,
        R_CUDA_G8_8,
        R_CUDA_G8_16,
        R_CUDA_G8_24,
        R_CUDA_G8_32,
        R_CUDA_G8_40,
        R_CUDA_G8_48,
        R_CUDA_G8_56,
        R_CUDA_FUNC_DESC_8_0,
        R_CUDA_FUNC_DESC_8_8,
        R_CUDA_FUNC_DESC_8_16,
        R_CUDA_FUNC_DESC_8_24,
        R_CUDA_FUNC_DESC_8_32,
        R_CUDA_FUNC_DESC_8_40,
        R_CUDA_FUNC_DESC_8_48,
        R_CUDA_FUNC_DESC_8_56,
        R_CUDA_ABS20_44,
        R_CUDA_SAMP_HEADER_INDEX_0,
        R_CUDA_UNIFIED,
        R_CUDA_UNIFIED_32,
        R_CUDA_UNIFIED_8_0,
        R_CUDA_UNIFIED_8_8,
        R_CUDA_UNIFIED_8_16,
        R_CUDA_UNIFIED_8_24,
        R_CUDA_UNIFIED_8_32,
        R_CUDA_UNIFIED_8_40,
        R_CUDA_UNIFIED_8_48,
        R_CUDA_UNIFIED_8_56,
        R_CUDA_UNIFIED32_LO_32,
        R_CUDA_UNIFIED32_HI_32,
        R_CUDA_ABS56_16_34,
        R_CUDA_CONST_FIELD22_37,

        // TODO: Rename!
        pub fn idk(self: @This(), sm: std.Target.nvptx.cpu) u64 {
            return switch (self) {
                .R_CUDA_NONE => 0,
                .R_CUDA_32 => 0,
                .R_CUDA_64 => 0,
                .R_CUDA_G32 => 0,
                .R_CUDA_G64 => 0,
                .R_CUDA_ABS32_26 => 0,
                .R_CUDA_TEX_HEADER_INDEX => 0,
                .R_CUDA_SAMP_HEADER_INDEX => 0,
                .R_CUDA_SURF_HW_DESC => 0,
                .R_CUDA_SURF_HW_SW_DESC => 0,
                .R_CUDA_ABS32_LO_26 => 0,
                .R_CUDA_ABS32_HI_26 => 0,
                .R_CUDA_ABS32_23 => 0,
                .R_CUDA_ABS32_LO_23 => 0,
                .R_CUDA_ABS32_HI_23 => 0,
                .R_CUDA_ABS24_26 => 0,
                .R_CUDA_ABS24_23 => 0,
                .R_CUDA_ABS16_26 => 0,
                .R_CUDA_ABS16_23 => 0,
                .R_CUDA_TEX_SLOT => 0,
                .R_CUDA_SAMP_SLOT => 0,
                .R_CUDA_SURF_SLOT => 0,
                .R_CUDA_TEX_BINDLESSOFF13_32 => 0,
                .R_CUDA_TEX_BINDLESSOFF13_47 => 0,
                .R_CUDA_CONST_FIELD19_28 => 0,
                .R_CUDA_CONST_FIELD19_23 => 0,
                .R_CUDA_TEX_SLOT9_49 => 0,
                .R_CUDA_6_31 => 0,
                .R_CUDA_2_47 => 0,
                .R_CUDA_TEX_BINDLESSOFF13_41 => 0,
                .R_CUDA_TEX_BINDLESSOFF13_45 => 0,
                .R_CUDA_FUNC_DESC32_23 => 0,
                .R_CUDA_FUNC_DESC32_LO_23 => 0,
                .R_CUDA_FUNC_DESC32_HI_23 => 0,
                .R_CUDA_FUNC_DESC_32 => 0,
                .R_CUDA_FUNC_DESC_64 => 0,
                .R_CUDA_CONST_FIELD21_26 => 0,
                .R_CUDA_QUERY_DESC21_37 => 0,
                .R_CUDA_CONST_FIELD19_26 => 0,
                .R_CUDA_CONST_FIELD21_23 => 0,
                .R_CUDA_PCREL_IMM24_26 => 0,
                .R_CUDA_PCREL_IMM24_23 => 0,
                .R_CUDA_ABS32_20 => 0,
                .R_CUDA_ABS32_LO_20 => 0,
                .R_CUDA_ABS32_HI_20 => 0,
                .R_CUDA_ABS24_20 => 0,
                .R_CUDA_ABS16_20 => 0,
                .R_CUDA_FUNC_DESC32_20 => 0,
                .R_CUDA_FUNC_DESC32_LO_20 => 0,
                .R_CUDA_FUNC_DESC32_HI_20 => 0,
                .R_CUDA_CONST_FIELD19_20 => 0,
                .R_CUDA_BINDLESSOFF13_36 => 0,
                .R_CUDA_SURF_HEADER_INDEX => 0,
                .R_CUDA_INSTRUCTION64 => 0,
                .R_CUDA_CONST_FIELD21_20 => 0,
                .R_CUDA_ABS32_32 => 0,
                .R_CUDA_ABS32_LO_32 => 0,
                .R_CUDA_ABS32_HI_32 => 0,
                .R_CUDA_ABS47_34 => 0,
                .R_CUDA_ABS16_32 => 0,
                .R_CUDA_ABS24_32 => 0,
                .R_CUDA_FUNC_DESC32_32 => 0,
                .R_CUDA_FUNC_DESC32_LO_32 => 0,
                .R_CUDA_FUNC_DESC32_HI_32 => 0,
                .R_CUDA_CONST_FIELD19_40 => 0,
                .R_CUDA_BINDLESSOFF14_40 => 0,
                .R_CUDA_CONST_FIELD21_38 => 0,
                .R_CUDA_INSTRUCTION128 => 0,
                .R_CUDA_YIELD_OPCODE9_0 => 0,
                .R_CUDA_YIELD_CLEAR_PRED4_87 => 0,
                .R_CUDA_32_LO => 0,
                .R_CUDA_32_HI => 0,
                .R_CUDA_UNUSED_CLEAR32 => 0,
                .R_CUDA_UNUSED_CLEAR64 => 0,
                .R_CUDA_ABS24_40 => 0,
                .R_CUDA_ABS55_16_34 => 0,
                .R_CUDA_8_0 => 0,
                .R_CUDA_8_8 => 0,
                .R_CUDA_8_16 => 0,
                .R_CUDA_8_24 => 0,
                .R_CUDA_8_32 => 0,
                .R_CUDA_8_40 => 0,
                .R_CUDA_8_48 => 0,
                .R_CUDA_8_56 => 0,
                .R_CUDA_G8_0 => 0,
                .R_CUDA_G8_8 => 0,
                .R_CUDA_G8_16 => 0,
                .R_CUDA_G8_24 => 0,
                .R_CUDA_G8_32 => 0,
                .R_CUDA_G8_40 => 0,
                .R_CUDA_G8_48 => 0,
                .R_CUDA_G8_56 => 0,
                .R_CUDA_FUNC_DESC_8_0 => 0,
                .R_CUDA_FUNC_DESC_8_8 => 0,
                .R_CUDA_FUNC_DESC_8_16 => 0,
                .R_CUDA_FUNC_DESC_8_24 => 0,
                .R_CUDA_FUNC_DESC_8_32 => 0,
                .R_CUDA_FUNC_DESC_8_40 => 0,
                .R_CUDA_FUNC_DESC_8_48 => 0,
                .R_CUDA_FUNC_DESC_8_56 => 0,
                .R_CUDA_ABS20_44 => 0,
                .R_CUDA_SAMP_HEADER_INDEX_0 => 0,
                .R_CUDA_UNIFIED => 0,
                .R_CUDA_UNIFIED_32 => 0,
                .R_CUDA_UNIFIED_8_0 => 0,
                .R_CUDA_UNIFIED_8_8 => 0,
                .R_CUDA_UNIFIED_8_16 => 0,
                .R_CUDA_UNIFIED_8_24 => 0,
                .R_CUDA_UNIFIED_8_32 => 0,
                .R_CUDA_UNIFIED_8_40 => 0,
                .R_CUDA_UNIFIED_8_48 => 0,
                .R_CUDA_UNIFIED_8_56 => 0,
                .R_CUDA_UNIFIED32_LO_32 => 0,
                .R_CUDA_UNIFIED32_HI_32 => 0,
                .R_CUDA_ABS56_16_34 => 0,
                .R_CUDA_CONST_FIELD22_37 => 0,
            };
        }
    };
}

const NvInfoItem = struct {
    format: Format,
    attribute: Attribute,
    value: Value,

    // https://github.com/VivekPanyam/cudaparsers/blob/main/src/cubin.rs#L109-L114
    // https://zhuanlan.zhihu.com/p/1961519233591674250
    const Format = enum(u8) {
        // EIFMT_ERROR = 0,
        EIFMT_NVAL = 1,
        EIFMT_BVAL,
        EIFMT_HVAL,
        EIFMT_SVAL,
    };

    // https://github.com/redplait/denvdis/blob/master/test/eiattrs.inc
    // https://github.com/redplait/denvdis/blob/master/ei_attrs.txt
    // https://github.com/VivekPanyam/cudaparsers/blob/main/src/cubin.rs#L119-L190
    // https://zhuanlan.zhihu.com/p/1961519233591674250
    const Attribute = enum(u8) {
        // EIATTR_ERROR = 0,
        EIATTR_PAD = 1,
        EIATTR_IMAGE_SLOT,
        EIATTR_JUMPTABLE_RELOCS,
        EIATTR_CTAIDZ_USED,
        EIATTR_MAX_THREADS,
        EIATTR_IMAGE_OFFSET,
        EIATTR_IMAGE_SIZE,
        EIATTR_TEXTURE_NORMALIZED,
        EIATTR_SAMPLER_INIT,
        EIATTR_PARAM_CBANK,
        EIATTR_SMEM_PARAM_OFFSETS, // Deprecated by EIATTR_KPARAM_INFO
        EIATTR_CBANK_PARAM_OFFSETS, // Deprecated by EIATTR_KPARAM_INFO
        EIATTR_SYNC_STACK, // Deprecated by EIATTR_CRS_STACK_SIZE
        EIATTR_TEXID_SAMPID_MAP,
        EIATTR_EXTERNS,
        EIATTR_REQNTID,
        EIATTR_FRAME_SIZE,
        EIATTR_MIN_STACK_SIZE,
        EIATTR_SAMPLER_FORCE_UNNORMALIZED,
        EIATTR_BINDLESS_IMAGE_OFFSETS, // Deprecated by R_CUDA_TEX_HEADER_INDEX
        EIATTR_BINDLESS_TEXTURE_BANK,
        EIATTR_BINDLESS_SURFACE_BANK,
        EIATTR_KPARAM_INFO,
        EIATTR_SMEM_PARAM_SIZE, // Deprecated by EIATTR_KPARAM_INFO
        // Can't find the leaked source code, so idk from here...
        EIATTR_CBANK_PARAM_SIZE,
        EIATTR_QUERY_NUMATTRIB,
        EIATTR_MAXREG_COUNT,
        EIATTR_EXIT_INSTR_OFFSETS,
        EIATTR_S2RCTAID_INSTR_OFFSETS,
        EIATTR_CRS_STACK_SIZE,
        EIATTR_NEED_CNP_WRAPPER,
        EIATTR_NEED_CNP_PATCH,
        EIATTR_EXPLICIT_CACHING,
        EIATTR_ISTYPEP_USED,
        EIATTR_MAX_STACK_SIZE,
        EIATTR_SUQ_USED,
        EIATTR_LD_CACHEMOD_INSTR_OFFSETS,
        EIATTR_LOAD_CACHE_REQUEST,
        EIATTR_ATOM_SYS_INSTR_OFFSETS,
        EIATTR_COOP_GROUP_INSTR_OFFSETS,
        EIATTR_COOP_GROUP_MASK_REGIDS,
        EIATTR_SW1850030_WAR,
        EIATTR_WMMA_USED,
        EIATTR_HAS_PRE_V10_OBJECT,
        EIATTR_ATOMF16_EMUL_INSTR_OFFSETS,
        EIATTR_ATOM16_EMUL_INSTR_REG_MAP,
        EIATTR_REGCOUNT,
        EIATTR_SW2393858_WAR,
        EIATTR_INT_WARP_WIDE_INSTR_OFFSETS,
        EIATTR_SHARED_SCRATCH,
        EIATTR_STATISTICS,
        EIATTR_INDIRECT_BRANCH_TARGETS,
        EIATTR_SW2861232_WAR,
        EIATTR_SW_WAR,
        EIATTR_CUDA_API_VERSION,
        EIATTR_NUM_MBARRIERS,
        EIATTR_MBARRIER_INSTR_OFFSETS,
        EIATTR_COROUTINE_RESUME_ID_OFFSETS,
        EIATTR_SAM_REGION_STACK_SIZE,
        EIATTR_PER_REG_TARGET_PERF_STATS,
        EIATTR_CTA_PER_CLUSTER,
        EIATTR_EXPLICIT_CLUSTER,
        EIATTR_MAX_CLUSTER_RANK,
        EIATTR_INSTR_REG_MAP,
        EIATTR_RESERVED_SMEM_USED,
        EIATTR_RESERVED_SMEM_0_SIZE,
        EIATTR_UCODE_SECTION_DATA,
        EIATTR_UNUSED_LOAD_BYTE_OFFSET,
        EIATTR_KPARAM_INFO_V2,
        EIATTR_SYSCALL_OFFSETS,
        EIATTR_SW_WAR_MEMBAR_SYS_INSTR_OFFSETS,
        EIATTR_GRAPHICS_GLOBAL_CBANK,
        EIATTR_SHADER_TYPE,
        EIATTR_VRC_CTA_INIT_COUNT,
        EIATTR_TOOLS_PATCH_FUNC,
        EIATTR_NUM_BARRIERS,
        EIATTR_TEXMODE_INDEPENDENT,
        EIATTR_PERF_STATISTICS,
        EIATTR_AT_ENTRY_FRAGMENTS,
        EIATTR_SPARSE_MMA_MASK,
        EIATTR_TCGEN05_1CTA_USED,
        EIATTR_TCGEN05_2CTA_USED,
        EIATTR_GEN_ERRBAR_AT_EXIT,
        EIATTR_REG_RECONFIG,
        EIATTR_ANNOTATIONS,
        EIATTR_SANITIZE,
        EIATTR_STACK_CANARY_TRAP_OFFSETS,
        EIATTR_STUB_FUNCTION_KIND,
        EIATTR_LOCAL_CTA_ASYNC_STORE_OFFSETS,
        EIATTR_MERCURY_FINALIZER_OPTIONS,
    };

    const Value = union(enum) {
        nval,
        bval: u8,
        hval: u16,
        sval: Sval,
    };

    const Sval = union(enum) {
        min_stack_size: MinStackSize,
        kparam_info: KParamInfo,
        raw: []const u8,

        const MinStackSize = packed struct {
            function: u32,
            min_size: u32,
        };

        const KParamInfo = packed struct {
            index: u32,
            ordinal: u16,
            offset: u16,
            log_alignment: u8,
            space: u4,
            cbank: u5,
            parameter_space: enum(u1) {
                cbank,
                smem,
            },
            size: u14,
        };
    };

    pub fn parse(reader: *Reader, endian: Endian) !@This() {
        const format = try reader.takeEnum(Format, endian);
        const attribute = try reader.takeEnum(Attribute, endian);
        // TODO: This appears to be correct for nval. Investigate if this is also correct for bval.
        const value_or_size = try reader.takeInt(u16, endian);
        const value: Value = switch (format) {
            .EIFMT_NVAL => .nval,
            .EIFMT_BVAL => .{ .bval = @truncate(value_or_size) },
            .EIFMT_HVAL => .{ .hval = value_or_size },
            .EIFMT_SVAL => .{ .sval = switch (attribute) {
                .EIATTR_MIN_STACK_SIZE => blk: {
                    std.debug.assert(value_or_size == @bitSizeOf(Sval.MinStackSize) / 8);
                    break :blk .{ .min_stack_size = try reader.takeStruct(Sval.MinStackSize, endian) };
                },
                .EIATTR_KPARAM_INFO => blk: {
                    std.debug.assert(value_or_size == @bitSizeOf(Sval.KParamInfo) / 8);
                    break :blk .{ .kparam_info = try reader.takeStruct(Sval.KParamInfo, endian) };
                },
                else => .{ .raw = try reader.take(value_or_size) },
            } },
        };
        return .{
            .format = format,
            .attribute = attribute,
            .value = value,
        };
    }
};

pub const Function = struct {
    name: []const u8,
    size: u64,
    virtual_address: u64,
    shared_memory: u32,
    register_count: u32,
    constants: []const Constant,
    params: []const Param, // https://developer.nvidia.com/blog/cuda-12-1-supports-large-kernel-parameters

    pub const Constant = struct {
        number: u32,
        address: u64,
        size: u64,
    };

    pub const Param = struct {
        index: u32,
        offset: u16,
        size: u16,
    };
};

const FunctionMap = struct {
    allocator: Allocator,
    entries: []Entry,
    length: usize,

    const Entry = struct {
        hash: u64,
        key: []const u8,
        name: ?[]const u8,
        size: ?u64,
        virtual_address: ?u64,
        shared_memory: ?u32,
        register_count: ?u32,
        constants: ArrayList(Function.Constant),
        params: ArrayList(Function.Param),
    };

    pub fn init(allocator: Allocator, capacity: usize) Allocator.Error!@This() {
        return .{
            .allocator = allocator,
            .entries = try allocator.alloc(Entry, capacity),
            .length = 0,
        };
    }

    pub fn deinit(self: *@This()) void {
        for (self.entries[0..self.length]) |entry| {
            self.allocator.free(entry.key);
            entry.constants.deinit(self.allocator);
            entry.params.deinit(self.allocator);
        }
        self.allocator.free(self.entries);
    }

    pub fn put(self: *@This(), key: []const u8, values: anytype) (Allocator.Error || error{CapacityExceeded})!void {
        if (self.length >= self.entries.len)
            return error.CapacityExceeded;
        const entry = self.getEntryPtr(key) orelse blk: {
            self.entries[self.length] = mem.zeroInit(Entry, .{
                .hash = Fnv1a.hash(key),
                .key = self.allocator.alloc(u8, key.len),
                .constants = try ArrayList(Function.Constant).initCapacity(self.allocator, 8), // TODO: Sane default.
                .params = try ArrayList(Function.Param).initCapacity(self.allocator, 8), // TODO: Sane default.
            });
            @memcpy(self.entries[self.length].key, key);
            break :blk &self.entries[self.length];
        };
        inline for (@typeInfo(@TypeOf(values)).@"struct".fields) |value_field| {
            if (mem.eql(u8, value_field.name, "hash") or mem.eql(u8, value_field.name, "key") or !@hasField(Entry, value_field.name))
                @compileError("TODO: Invalid field");
            if (mem.eql(u8, value_field.name, "constants") or mem.eql(u8, value_field.name, "params")) {}
            // @field(entry, value_field.name).addOne(self.allocator) = @field(values, value_field.name)
            else @field(entry, value_field.name) = @field(values, value_field.name);
        }
    }

    pub fn get(self: *@This(), key: []const u8) error{ Todo, FunctionIncomplete }!Function {
        self.getEntryPtr(key) orelse return error.Todo;
    }

    fn getEntryPtr(self: *@This(), key: []const u8) ?*Entry {
        const hash = Fnv1a.hash(key);
        for (self.entries[0..self.length]) |*entry|
            if (entry.hash == hash and mem.eql(u8, entry.key, key))
                return entry;
        return null;
    }
};

pub const Cubin = struct {
    function_map: FunctionMap,

    pub const ParseFileOptions = struct {
        mmap: bool = false,
    };

    pub fn parseFilePath(path: [:0]const u8, backing_buffer: ?[]u8, allocator: Allocator, options: ParseFileOptions) !@This() {
        const file = try std.fs.cwd().openFileZ(path, .{ .mode = .read_only });
        defer file.close();
        return .parseFile(file, backing_buffer, allocator, options);
    }

    pub fn parseFile(file: File, backing_buffer: ?[]u8, allocator: Allocator, options: ParseFileOptions) !@This() {
        if (options.mmap) {
            const stat = try posix.fstat(file.handle); // file.stat();
            const buffer = try posix.mmap(null, @intCast(stat.size), posix.PROT.READ, .{ .TYPE = .PRIVATE }, file.handle, 0);
            defer posix.munmap(buffer);
            return .parseBuffer(buffer, allocator);
        } else {
            var abstract_reader: AbstractReader = .initFile(file.reader(backing_buffer orelse &.{}));
            return parseAbstractReader(&abstract_reader, allocator);
        }
    }

    pub fn parseBuffer(buffer: []const u8, allocator: Allocator) !@This() {
        var abstract_reader: AbstractReader = .initBuffer(buffer);
        return parseAbstractReader(&abstract_reader, allocator);
    }

    pub fn parseAbstractReader(abstract_reader: *AbstractReader, allocator: Allocator) !@This() {
        var reader = abstract_reader.reader();

        const ident = try reader.peek(elf.EI.NIDENT);
        if (!mem.eql(u8, ident[0..4], elf.MAGIC)) return error.InvalidElfMagic;
        if (ident[elf.EI.VERSION] != 1) return error.InvalidElfVersion;
        if (@as(elf.OSABI, @enumFromInt(ident[elf.EI.OSABI])) != .CUDA) return error.InvalidElfOsAbi;

        const endian: Endian = switch (@as(elf.DATA, @enumFromInt(ident[elf.EI.DATA]))) {
            .@"2LSB" => .little,
            .@"2MSB" => .big,
            else => return error.InvalidElfEndian,
        };

        return switch (@as(elf.CLASS, @enumFromInt(ident[elf.EI.CLASS]))) {
            .@"32" => parseAbstractReaderByClass(elf.Elf32, abstract_reader, endian, allocator),
            .@"64" => parseAbstractReaderByClass(elf.Elf64, abstract_reader, endian, allocator),
            else => return error.InvalidElfClass,
        };
    }

    inline fn parseAbstractReaderByClass(comptime ElfType: type, abstract_reader: *AbstractReader, endian: Endian, allocator: Allocator) !@This() {
        const reader = abstract_reader.reader();

        const header = try reader.takeStruct(ElfType.Ehdr, endian);
        if (header.machine != .CUDA) return error.InvalidElfMachine;

        var section_headers = try allocator.alloc(ElfType.Shdr, header.shnum);
        defer allocator.free(section_headers);
        try abstract_reader.seekTo(header.shoff);
        for (section_headers) |*section_header|
            section_header.* = try reader.takeStruct(ElfType.Shdr, endian);

        var fixed_byte_count: usize = 0;
        var padding_byte_count: usize = 0;
        for (section_headers) |section_header| if (section_header.type == elf.SHT_PROGBITS) {
            if (section_header.size == 0) {
                std.debug.assert(@min(section_header.addralign, 128) % 128 == 0);
                // TODO
                const alignment = mem.alignForward(usize, section_header.size, @max(section_header.addralign, 128));
                padding_byte_count += (alignment - padding_byte_count) % alignment;
            } else {
                fixed_byte_count = @max(fixed_byte_count, section_header.addr + section_header.size);
            }
        };

        // std.debug.print("{d}\n", .{byte_count});
        // const image = try allocator.alloc(u8, byte_count);
        // defer allocator.free(image);

        // for (section_headers) |section_header| if (section_header.type == elf.SHT_PROGBITS) {
        //     if (section_header.addr != 0) {
        //         try abstract_reader.seekTo(section_header.offset);
        //         @memcpy(image[section_header.addr..][0..section_header.size], try reader.peek(section_header.size));
        //     }
        // };

        const string_table_header = section_headers[header.shstrndx];
        try abstract_reader.seekTo(string_table_header.offset);
        const string_table = try reader.peek(string_table_header.size);

        // for (section_headers) |section_header| {
        //     if (switch (section_header.type) {
        //         elf.SHT_REL => mem.cutPrefix(u8, mem.span(@as([*:0]const u8, @ptrCast(string_table[section_header.name..]))), ".rel"),
        //         elf.SHT_RELA => mem.cutPrefix(u8, mem.span(@as([*:0]const u8, @ptrCast(string_table[section_header.name..]))), ".rela"),
        //         else => continue,
        //     }) |target_section_name| {
        //         std.debug.print("target_section_name: {s}\n", .{target_section_name});
        //     }
        // }

        var function_map: FunctionMap = try .init(allocator, section_headers.len);

        for (section_headers) |section_header| switch (section_header.type) {
            elf.SHT_REL, elf.SHT_RELA => {
                if (mem.cutPrefix(u8, mem.span(@as([*:0]const u8, @ptrCast(string_table[section_header.name..]))), ".rel.")) |_| {
                }
            },
            elf.SHT_PROGBITS => {
                const section_name = mem.span(@as([*:0]const u8, @ptrCast(string_table[section_header.name..])));
                if (mem.cutPrefix(u8, section_name, ".text.")) |function_name| {
                    // std.debug.print("function_name: {s}\n", .{function_name});
                    try function_map.put(function_name, .{
                        .name = function_name,
                        .size = section_header.size,
                        .virtual_address = section_header.addr, // TODO: + virtual_addr
                        .register_count = section_header.info >> 24, // TODO" This should be from its own section???
                    });
                } else if (mem.cutPrefix(u8, section_name, ".nv.constant")) |constant_number_and_function_name| {
                    const constant_number, const function_name = mem.cutScalar(u8, constant_number_and_function_name, '.') orelse unreachable; // TODO: Remove unreachable?
                    std.debug.print("constant_number: {s}\n", .{constant_number});
                    std.debug.print("function_name: {s}\n", .{function_name});
                    // std.fmt.parseUnsigned(usize, constant_number, 10);
                    // var x = 0;
                    // for (constant_number) |constant_digit| {
                    //     x = try std.math.mul(usize, x, 10);
                    //     x = try std.math.add(usize, x, constant_digit - '0');
                    // }
                }
            },
            elf.SHT_NOBITS => {
                if (mem.cutPrefix(u8, mem.span(@as([*:0]const u8, @ptrCast(string_table[section_header.name..]))), ".nv.shared.")) |function_name| {
                    // std.debug.print("function_name: {s}\n", .{function_name});
                    // std.debug.print("shared_memory: {d}\n", .{section_header.entsize});
                    try function_map.put(function_name, .{ .shared_memory = section_header.entsize });
                }
            },
            elf.SHT_LOPROC + 0x0 => {
                if (mem.cutPrefix(u8, mem.span(@as([*:0]const u8, @ptrCast(string_table[section_header.name..]))), ".nv.info.")) |function_name| {
                    std.debug.print("function_name: {s}\n", .{function_name});
                    try abstract_reader.seekTo(section_header.offset);
                    while (reader.seek < section_header.size) {
                        const info_item: NvInfoItem = try .parse(reader, endian);
                        switch (info_item.attribute) {
                            .EIATTR_MIN_STACK_SIZE => {},
                            .EIATTR_KPARAM_INFO => {},
                            else => {},
                        }
                        std.debug.print("{} {any}\n", .{ info_item.attribute, info_item.value });
                    }
                }
            },
            else => continue,
        };

        return .{ .function_map = function_map };
    }

    pub fn deinit(self: *@This()) void {
        // TODO: Free virtual_address
        self.function_map.deinit();
    }
};

test Cubin {} // TODO
