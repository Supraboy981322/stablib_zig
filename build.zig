//usage of stdlib:
//  - std.Build
// steps to remove:
//  - probably not possible at the moment

const std = @import("std"); //sadly required for the build system
const Build = std.Build;
const Target = std.Target.Query;

const test_targets = [_]Target{
    .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
    },
};

pub fn build(b:*Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const opts = b.addOptions();
    const root = b.option([]const u8, "root", "override module root dir") orelse "src";

    const module = b.addModule("stablib", .{
        .root_source_file = b.path(b.pathJoin(&.{ root, "module.zig" })),
        .target = target,
        .optimize = optimize,
    });
    module.addOptions("options", opts);

    const test_step = b.step("test", "run the module tests");
    for (test_targets) |t| {
        const target_tests = b.addTest(.{
            .root_module = b.createModule(.{
                .root_source_file = b.path(b.pathJoin(&.{ root, "module.zig" })),
                .target = b.resolveTargetQuery(t),
            }),
        });
        const run_tests = b.addRunArtifact(target_tests);
        run_tests.skip_foreign_checks = true;
        test_step.dependOn(&run_tests.step);
    }
}
