const std = @import("std");
const zlinter = @import("zlinter");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .abi = .musl,
            .os_tag = .linux,
        },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseFast,
    });

    if (target.result.os.tag != .linux)
        return error.LinuxOnly;

    const llvm_enable = b.option(bool, "llvm", "TODO") orelse if (optimize != .Debug) true else null;
    const lld_enable = b.option(bool, "lld", "TODO") orelse llvm_enable;
    const strip = b.option(bool, "strip", "TODO") orelse (optimize != .Debug);
    const tracy_enable = b.option(bool, "tracy", "TODO") orelse (optimize == .Debug and target.result.cpu.arch.endian() == .little);
    const tracy_callstack_enable = b.option(bool, "tracy-callstack", "TODO") orelse true;
    const tracy_default_callstack_depth = b.option(u32, "tracy-default-callstack-depth", "TODO");

    const exe = b.addExecutable(.{
        .name = "cuda",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            // .imports
            .target = target,
            .optimize = optimize,
            .link_libc = false,
            .link_libcpp = false,
            // .single_threaded
            .strip = strip,
            // .unwind_tables
            // .dwarf_format
            // .code_model
            // .stack_protector
            // .stack_check
            // .sanitize_c
            // .sanitize_thread
            // .fuzz
            // .valgrind
            // .pic
            // .red_zone
            .omit_frame_pointer = optimize != .Debug,
            .error_tracing = optimize == .Debug,
            // .no_builtin
        }),
        // .version
        .linkage = .static,
        // .max_rss
        .use_llvm = llvm_enable,
        .use_lld = lld_enable,
        // .zig_lib_dir
    });

    const options = b.addOptions();
    options.addOption(bool, "tracy_enable", tracy_enable);
    options.addOption(bool, "tracy_callstack_enable", tracy_callstack_enable);
    options.addOption(?u32, "tracy_default_callstack_depth", tracy_default_callstack_depth);
    exe.root_module.addOptions("build_options", options);

    const open_gpu_kernel_modules_src = b.dependency("open_gpu_kernel_modules", .{});
    exe.addIncludePath(open_gpu_kernel_modules_src.path("kernel-open"));
    // exe.installHeadersDirectory(open_gpu_kernel_modules_src.path("kernel-open"), "open_gpu_kernel_modules", .{});

    if (tracy_enable) if (b.lazyDependency("tracy", .{})) |tracy_src| {
        const tracy_lib = b.addLibrary(.{
            .linkage = .static,
            .name = "tracy",
            .root_module = b.createModule(.{
                // .root_source_file
                // .imports
                .target = target,
                .optimize = optimize,
                .link_libc = true, // target.result.abi == .msvc,
                .link_libcpp = true, // target.result.abi != .msvc,
                // .single_threaded
                .strip = strip,
                // .unwind_tables
                // .dwarf_format
                // .code_model
                // .stack_protector
                // .stack_check
                // .sanitize_c
                // .sanitize_thread
                // .fuzz
                // .valgrind
                // .pic
                // .red_zone
                .omit_frame_pointer = optimize != .Debug,
                .error_tracing = optimize == .Debug,
                // .no_builtin
            }),
            // .version
            // .max_rss
            .use_llvm = llvm_enable,
            .use_lld = lld_enable,
            // .zig_lib_dir
        });
        tracy_lib.addCSourceFile(.{
            .file = tracy_src.path("public/TracyClient.cpp"),
            .flags = if (target.result.os.tag == .windows) &.{"-fms-extensions"} else &.{}, // TODO: "-fno-sanitize=undefined"?
            .language = .cpp,
        });
        tracy_lib.root_module.addCMacro("TRACY_ENABLE", "");
        if (!tracy_callstack_enable) tracy_lib.root_module.addCMacro("TRACY_NO_CALLSTACK", "1");
        if (tracy_default_callstack_depth) |callstack_depth| tracy_lib.root_module.addCMacro("TRACY_CALLSTACK", "\"" ++ std.fmt.digits2(@intCast(callstack_depth)) ++ "\"");
        tracy_lib.addIncludePath(tracy_src.path("public/tracy"));
        tracy_lib.installHeadersDirectory(tracy_src.path("public"), "tracy", .{});
        if (target.result.os.tag == .windows) {
            tracy_lib.linkSystemLibrary("dbghelp");
            tracy_lib.linkSystemLibrary("ws2_32");
        }
        exe.linkLibrary(tracy_lib);
    };

    b.installArtifact(exe);

    // TODO: Clean-up the rest!

    const run_step = b.step("run", "Run the app");
    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);

    const exe_tests = b.addTest(.{ .root_module = exe.root_module });
    const test_step = b.step("test", "Run tests");
    const test_cmd = b.addRunArtifact(exe_tests);
    test_step.dependOn(&test_cmd.step);

    const lint_cmd = b.step("lint", "Lint source code");
    lint_cmd.dependOn(step: {
        var builder = zlinter.builder(b, .{});
        // TODO: List and configure all rules: https://github.com/KurtWagner/zlinter/blob/master/RULES.md
        inline for (@typeInfo(zlinter.BuiltinLintRule).@"enum".fields) |field| switch (@as(zlinter.BuiltinLintRule, @enumFromInt(field.value))) {
            .import_ordering => builder.addRule(.{ .builtin = .import_ordering }, .{ .severity = .off }),
            .no_todo => builder.addRule(.{ .builtin = .no_todo }, .{ .severity = .off }),
            .no_undefined => builder.addRule(.{ .builtin = .no_undefined }, .{ .severity = .off }),
            .require_doc_comment => builder.addRule(.{ .builtin = .require_doc_comment }, .{ .public_severity = .off }),
            else => |rule| builder.addRule(.{ .builtin = rule }, .{}),
        };
        break :step builder.build();
    });
}
