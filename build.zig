const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    _ = b.addModule("root", .{
        .root_source_file = b.path("src/main.zig"),
    });

    const test_step = b.step("test", "Run wgpu_preprocessor tests");

    const tests = b.addTest(.{
        .name = "wgpu-preprocessor-tests",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(tests);

    test_step.dependOn(&b.addRunArtifact(tests).step);
}

// pub fn build(b: *std.Build) void {
//     const target = b.standardTargetOptions(.{});

//     const options = .{
//         .optimize = b.option(
//             std.builtin.OptimizeMode,
//             "optimize",
//             "Select optimization mode",
//         ) orelse b.standardOptimizeOption(.{
//             // .preferred_optimize_mode = .ReleaseFast,
//         }),
//         .enable_cross_platform_determinism = b.option(
//             bool,
//             "enable_cross_platform_determinism",
//             "Enable cross-platform determinism",
//         ) orelse true,
//     };

//     const options_step = b.addOptions();
//     inline for (std.meta.fields(@TypeOf(options))) |field| {
//         options_step.addOption(field.type, field.name, @field(options, field.name));
//     }

//     const options_module = options_step.createModule();
//     _ = b.addModule("root", .{
//         .root_source_file = b.path("src/root.zig"),
//         .imports = &.{
//             .{ .name = "wgsl_preprocessor_options", .module = options_module },
//         },
//     });

//     const test_step = b.step("test", "Run wgsl_preprocessor tests");

//     const tests = b.addTest(.{
//         .name = "wgsl-preprocessor-tests",
//         .root_source_file = b.path("src/main.zig"),
//         .target = target,
//         .optimize = options.optimize,
//     });
//     b.installArtifact(tests);

//     tests.root_module.addImport("wgsl_preprocessor_options", options_module);

//     test_step.dependOn(&b.addRunArtifact(tests).step);

//     // const benchmark_step = b.step("benchmark", "Run wgsl_preprocessor benchmarks");

//     // const benchmarks = b.addExecutable(.{
//     //     .name = "wgsl-preprocessor-benchmarks",
//     //     .root_source_file = b.path("src/benchmark.zig"),
//     //     .target = target,
//     //     .optimize = options.optimize,
//     // });
//     // b.installArtifact(benchmarks);

//     // benchmarks.root_module.addImport("wgsl_preprocessor", wgsl_preprocessor);

//     // benchmark_step.dependOn(&b.addRunArtifact(benchmarks).step);
// }

// // pub fn build(b: *std.Build) void {
// //     //     const target = b.standardTargetOptions(.{});
// //     //     const optimize = b.standardOptimizeOption(.{});

// //     //     // const lib = b.addStaticLibrary(.{
// //     //     //     .name = "wgsl_preprocessor",
// //     //     //     .root_source_file = b.path("src/root.zig"),
// //     //     //     .target = target,
// //     //     //     .optimize = optimize,
// //     //     // });

// //     //     // b.installArtifact(lib);

// //     //     const lib_unit_tests = b.addTest(.{
// //     //         .root_source_file = b.path("src/root.zig"),
// //     //         .target = target,
// //     //         .optimize = optimize,
// //     //     });

// //     //     const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

// //     //     const test_step = b.step("test", "Run unit tests");
// //     //     test_step.dependOn(&run_lib_unit_tests.step);
// //     // }

// //     // fn temp(b: *std.Build) void {
// //     const target = b.standardTargetOptions(.{});
// //     const options = .{
// //         .optimize = b.option(
// //             std.builtin.OptimizeMode,
// //             "optimize",
// //             "Select optimization mode",
// //         ) orelse b.standardOptimizeOption(.{
// //             // .preferred_optimize_mode = .ReleaseFast,
// //         }),
// //         .enable_cross_platform_determinism = b.option(
// //             bool,
// //             "enable_cross_platform_determinism",
// //             "Enable cross-platform determinism",
// //         ) orelse true,
// //     };

// //     const options_step = b.addOptions();
// //     inline for (std.meta.fields(@TypeOf(options))) |field| {
// //         options_step.addOption(field.type, field.name, @field(options, field.name));
// //     }

// //     const options_module = options_step.createModule();
// //     const wgsl_preprocessor = b.addModule("root", .{
// //         .root_source_file = b.path("src/root.zig"),
// //         .imports = &.{
// //             .{ .name = "wgpu_preprocessor_options", .module = options_module },
// //         },
// //     });

// //     const test_step = b.step("test", "Run wgsl_preprocessor tests");

// //     const tests = b.addTest(.{
// //         .name = "wgsl-preprocessor-tests",
// //         .root_source_file = b.path("src/main.zig"),
// //         .target = target,
// //         .optimize = options.optimize,
// //     });
// //     b.installArtifact(tests);

// //     tests.root_module.addImport("wgsl_preprocessor_options", options_module);

// //     test_step.dependOn(&b.addRunArtifact(tests).step);

// //     const lib_unit_tests = b.addTest(.{
// //         .root_source_file = b.path("src/root.zig"),
// //         .target = target,
// //         // .optimize = options.optimize,
// //     });

// //     const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

// //     // const test_step = b.step("test", "Run unit tests");
// //     test_step.dependOn(&run_lib_unit_tests.step);
// // }
