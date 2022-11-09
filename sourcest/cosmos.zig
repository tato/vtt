const std = @import("std");
const platform = @import("platform.zig");

const Cosmos = @import("cosmos/Cosmos.zig");

var cosmos = @as(*Cosmos, undefined);

pub fn init(allocator: std.mem.Allocator) void {
    cosmos = allocator.create(Cosmos) catch unreachable;
    cosmos.* = .{ .allocator = allocator };
}

pub fn deinit() void {
    if (@import("builtin").mode == .Debug) {
        const allocator = cosmos.allocator;
        cosmos.deinit();
        allocator.destroy(cosmos);
    }
}

pub fn update() void {
    if (platform.rl.IsMouseButtonPressed(platform.rl.MOUSE_BUTTON_RIGHT)) {
        const mouse = platform.rl.GetMousePosition();
        cosmos.put_button_at(@floatCast(f64, mouse.x), @floatCast(f64, mouse.y));
    }
}

pub fn paint() void {
    cosmos.paint();
}
