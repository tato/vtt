const std = @import("std");

const GenericCard = @import("GenericCard.zig");

const Universe = @This();
allocator: std.mem.Allocator,
cards: std.ArrayListUnmanaged(GenericCard),

pub fn deinit(uni: *Universe) void {
    for (uni.cards.items) |*card|
        card.deinit(uni.allocator);
    uni.cards.deinit(uni.allocator);
    uni.* = undefined;
}
