const std = @import("std");

const types = @import("types.zig");
const CommonCard = @import("CommonCard.zig");

const Universe = @This();
allocator: std.mem.Allocator,
cards: std.ArrayListUnmanaged(CommonCard),

pub fn deinit(uni: *Universe) void {
    for (uni.cards.items) |*card|
        card.deinit(uni.allocator);
    uni.cards.deinit(uni.allocator);
    uni.* = undefined;
}
