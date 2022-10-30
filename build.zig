const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("vtt", "source/main.zig");
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addArgs(@as([]const []const u8, b.args orelse &.{}));

    const exe_tests = b.addTest("source/main.zig");

    inline for (.{ exe, exe_tests }) |goal| {
        goal.setTarget(target);
        goal.setBuildMode(mode);
        // goal.addPackagePath("toml", "packages/sometoml/toml.zig");
        goal.addPackagePath("toml", "packages/toml-zig/src/value.zig");

        const raylib = @import("packages/raylib/build.zig");
        goal.addPackage(raylib.raylib_pkg);
        goal.linkLibrary(raylib.getRaylib(b, mode, target));
    }

    b.step("run", "Run the app").dependOn(&run_cmd.step);
    b.step("test", "Run unit tests").dependOn(&exe_tests.step);
}
