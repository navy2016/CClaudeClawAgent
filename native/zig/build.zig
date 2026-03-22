const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_arch = .aarch64,
            .os_tag = .linux,
            .abi = .android,
        },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSmall,
    });

    const lib = b.addSharedLibrary(.{
        .name = "cclaudeclaw",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();
    
    // Android NDK specific settings
    lib.root_module.addCMacro("ANDROID", "");
    
    b.installArtifact(lib);
}
