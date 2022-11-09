const std = @import("std");
const platform = @import("../platform.zig");

const Button = @This();
left: f64,
top: f64,

pub fn deinit(button: *Button) void {
    button.* = undefined;
}

pub fn paint(button: *const Button) void {
    const rect = platform.rl.Rectangle{
        .x = @floatCast(f32, button.left - 2),
        .y = @floatCast(f32, button.top - 2),
        .width = 4,
        .height = 4,
    };
    platform.rl.DrawRectangleRec(rect, platform.rl.BLACK);
}
