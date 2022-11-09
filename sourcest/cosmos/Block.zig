const std = @import("std");
const platform = @import("../platform.zig");

const Block = @This();
first: ?*Block,
last: ?*Block,
next: ?*Block,
prev: ?*Block,
parent: ?*Block,

text: []const u8,
flags: Flags,

computed_position: [2]f64,
computed_size: [2]f64,

pub const Flags = packed struct(u32) {
    display_text: bool = false,
    positioned: bool = false,
    clickable: bool = false,
};

pub fn deinit(block: *Block, allocator: std.mem.Allocator) void {
    if (block.text.len > 0)
        allocator.free(block.text);
    block.* = undefined;
}

pub fn paint(block: *const Block) void {
    const rect = platform.rl.Rectangle{
        .x = @floatCast(f32, block.computed_position[0]),
        .y = @floatCast(f32, block.computed_position[1]),
        .width = @floatCast(f32, block.computed_size[0]),
        .height = @floatCast(f32, block.computed_size[1]),
    };
    platform.rl.DrawRectangleRec(rect, platform.rl.BLACK);
}
