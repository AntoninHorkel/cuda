const std = @import("std");
const elf = std.elf;
const mem = std.mem;
const posix = std.posix;
const Allocator = std.mem.Allocator;
const Endian = std.builtin.Endian;
const File = std.fs.File;
const Fnv1a = std.hash.Fnv1a_64;
const Reader = std.Io.Reader;

const AbstractReader = union(enum) {
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

const NvInfoItem = struct {
    format: Format,
    attribute: Attribute,
    value: Value,

    const Format = enum(u8) {
        EIFMT_NVAL = 0x01,
        EIFMT_BVAL,
        EIFMT_HVAL,
        EIFMT_SVAL,
    };

    const Attribute = enum(u8) {
        EIATTR_ERROR = 0x00,
        EIATTR_PAD,
        EIATTR_IMAGE_SLOT,
        EIATTR_JUMPTABLE_RELOCS,
        EIATTR_CTAIDZ_USED,
        EIATTR_MAX_THREADS,
        EIATTR_IMAGE_OFFSET,
        EIATTR_IMAGE_SIZE,
        EIATTR_TEXTURE_NORMALIZED,
        EIATTR_SAMPLER_INIT,
        EIATTR_PARAM_CBANK,
        EIATTR_SMEM_PARAM_OFFSETS,
        EIATTR_CBANK_PARAM_OFFSETS,
        EIATTR_SYNC_STACK,
        EIATTR_TEXID_SAMPID_MAP,
        EIATTR_EXTERNS,
        EIATTR_REQNTID,
        EIATTR_FRAME_SIZE,
        EIATTR_MIN_STACK_SIZE,
        EIATTR_SAMPLER_FORCE_UNNORMALIZED,
        EIATTR_BINDLESS_IMAGE_OFFSETS,
        EIATTR_BINDLESS_TEXTURE_BANK,
        EIATTR_BINDLESS_SURFACE_BANK,
        EIATTR_KPARAM_INFO,
        EIATTR_SMEM_PARAM_SIZE,
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
        EIATTR_COOP_GROUP_MAX_REGIDS,
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
        // New between CUDA 10.2 and 11.6
        EIATTR_INDIRECT_BRANCH_TARGETS,
        EIATTR_SW2861232_WAR,
        EIATTR_SW_WAR,
        EIATTR_CUDA_API_VERSION,
        EIATTR_NUM_MBARRIERS,
        EIATTR_MBARRIER_INSTR_OFFSETS,
        EIATTR_COROUTINE_RESUME_ID_OFFSETS,
        EIATTR_SAM_REGION_STACK_SIZE,
        EIATTR_PER_REG_TARGET_PERF_STATS,
        // New between CUDA 11.6 and 11.8
        EIATTR_CTA_PER_CLUSTER,
        EIATTR_EXPLICIT_CLUSTER,
        EIATTR_MAX_CLUSTER_RANK,
        EIATTR_INSTR_REG_MAP,
    };

    const Value = union(enum) {
        nval: u16,
        bval: u16, // TODO: Or u8?
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
            is_cbank: bool,
            size: u14,
        };
    };

    pub fn parse(reader: *Reader, endian: Endian) !@This() {
        const format = try reader.takeEnum(Format, endian);
        const attribute = try reader.takeEnum(Attribute, endian);
        const value_or_size = try reader.takeInt(u16, endian);
        const value: Value = switch (format) {
            .EIFMT_NVAL => .{ .nval = value_or_size },
            .EIFMT_BVAL => .{ .bval = value_or_size },
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

pub const Cubin = struct {
    virtual_address: u32,
    functions: []const Function,

    pub const Function = struct {
        name: []const u8,
        size: u64,
        virtual_address: u64,
        shared_memory: u32,
        register_count: u32,
        constants: []const Constant,
        params: []const Param,

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

        const Map = struct {
            entries: []Entry,
            length: usize,

            const Entry = struct {
                hash: u64,
                key: []const u8,
                function: MaybeFunction,

                const MaybeFunction = blk: {
                    const function_fields = @typeInfo(Function).@"struct".fields;
                    var fields: [function_fields.len]std.builtin.Type.StructField = undefined;
                    for (function_fields, &fields) |function_field, *field|
                        field.* = .{
                            .name = function_field.name,
                            .type = ?function_field.type,
                            .default_value_ptr = function_field.default_value_ptr,
                            .is_comptime = function_field.is_comptime,
                            .alignment = @alignOf(?function_field.type),
                        };
                    break :blk @Type(.{ .@"struct" = .{
                        .decls = &.{},
                        .fields = &fields,
                        .is_tuple = false,
                        .layout = .auto,
                    } });
                };
            };

            pub fn init(allocator: Allocator, capacity: usize) Allocator.Error!@This() {
                return .{ .entries = try allocator.alloc(Entry, capacity), .length = 0 };
            }

            pub fn deinit(self: *@This(), allocator: Allocator) void {
                allocator.free(self.entries);
            }

            pub fn put(self: *@This(), key: []const u8, values: anytype) error{CapacityExceeded}!void {
                if (self.length >= self.entries.len)
                    return error.CapacityExceeded;
                const hash = Fnv1a.hash(key);
                const index = for (self.entries[0..self.length], 0..) |entry, index| {
                    if (entry.hash == hash and mem.eql(u8, entry.key, key))
                        break index;
                } else blk: {
                    self.entries[self.length].hash = hash;
                    self.entries[self.length].key = key;
                    self.length += 1;
                    break :blk self.length - 1;
                };
                inline for (@typeInfo(@TypeOf(values)).@"struct".fields) |value_field|
                    @field(self.entries[index], value_field.name) = @field(values, value_field.name);
            }

            pub fn collect(self: *@This(), allocator: Allocator) (Allocator.Error || error{Invalid})![]const Function {
                const functions = try allocator.alloc(Function, self.length);
                for (self.entries[0..self.length], functions) |entry, *function| {
                    inline for (@typeInfo(Entry.MaybeFunction).@"struct".fields) |function_field| {
                        const e = @field(entry.function, function_field.name) orelse return error.Invalid;
                        switch (@typeInfo(@typeInfo(function_field.type).optional.child)) {
                            .int => @field(function, function_field.name) = e,
                            .pointer => @memcpy(@field(function, function_field.name), e),
                            else => @compileError("TODO: Unhandled type"),
                        }
                    }
                }
                return functions;
            }
        };
    };

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

        // var fixed_byte_count: usize = 0;
        // var padding_byte_count: usize = 0;
        // for (section_headers) |section_header| {
        //     switch (section_header.type) {
        //         elf.SHT_PROGBITS => {
        //             if (section_header.size == 0) {
        //                 std.debug.assert(@min(section_header.addralign, 128) % 128 == 0);
        //                 // TODO
        //                 const alignment = mem.alignForward(usize, section_header.size, @max(section_header.addralign, 128));
        //                 padding_byte_count += (alignment - padding_byte_count) % alignment;
        //             } else {
        //                 fixed_byte_count = @max(fixed_byte_count, section_header.addr + section_header.size);
        //             }
        //         },
        //         // elf.SHT_SYMTAB => symtab_index = index,
        //         // elf.SHT_STRTAB => std.debug.assert(index == header.shstrndx),
        //         else => {},
        //     }
        // }

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

        var function_map: Function.Map = try .init(allocator, section_headers.len);
        defer function_map.deinit(allocator);

        for (section_headers) |section_header| switch (section_header.type) {
            elf.SHT_PROGBITS => {
                const section_name = mem.span(@as([*:0]const u8, @ptrCast(string_table[section_header.name..])));
                if (mem.cutPrefix(u8, section_name, ".text.")) |function_name| {
                    std.debug.print("function_name: {s}\n", .{function_name});
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
                    std.debug.print("function_name: {s}\n", .{function_name});
                    std.debug.print("shared_memory: {d}\n", .{section_header.entsize});
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

        return .{
            .virtual_address = 0,
            .functions = try function_map.collect(allocator),
        };
    }

    pub fn deinit(self: *@This(), allocator: Allocator) void {
        // TODO: Free virtual_address
        allocator.free(self.functions);
    }
};

test Cubin {} // TODO
