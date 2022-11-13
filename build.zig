const std = @import("std");

const raylib = @import("packages/raylib/build.zig");

const packages = struct {
    const platform = std.build.Pkg{
        .name = "platform",
        .source = .{ .path = "source/platform/_.zig" },
        .dependencies = &.{raylib.raylib_pkg},
    };
    const ui = std.build.Pkg{
        .name = "ui",
        .source = .{ .path = "source/ui/_.zig" },
        .dependencies = &.{platform},
    };
    const cosmos = std.build.Pkg{
        .name = "cosmos",
        .source = .{ .path = "source/cosmos/_.zig" },
        .dependencies = &.{},
    };
};

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

        goal.addPackage(packages.platform);
        goal.addPackage(packages.ui);
        goal.addPackage(packages.cosmos);

        goal.linkLibrary(raylib.getRaylib(b, mode, target));
    }

    b.step("run", "Run the app").dependOn(&run_cmd.step);
    b.step("test", "Run unit tests").dependOn(&exe_tests.step);

    buildest(b, target, mode);
}

fn buildest(b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) void {
    const exe = b.addExecutable("exp", "sourcest/main.zig");
    exe.install();
    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addArgs(@as([]const []const u8, b.args orelse &.{}));

    const exe_tests = b.addTest("sourcest/main.zig");

    inline for (.{ exe, exe_tests }) |goal| {
        goal.setTarget(target);
        goal.setBuildMode(mode);

        goal.addPackage(raylib.raylib_pkg);
        goal.linkLibrary(raylib.getRaylib(b, mode, target));

        goal.addPackage(raylib.raygui_pkg);
        goal.linkLibrary(raylib.getRaygui(b, mode, target));

        goal.addPackage(raylib.raymath_pkg);
        goal.linkLibrary(raylib.getRaymath(b, mode, target));
    }

    b.step("runest", "Run the app").dependOn(&run_cmd.step);
    b.step("testest", "Run unit tests").dependOn(&exe_tests.step);
}
