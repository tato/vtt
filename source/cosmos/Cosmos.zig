const std = @import("std");

const types = @import("types.zig");
const CommonCard = @import("CommonCard.zig");

const Cosmos = @This();
allocator: std.mem.Allocator,
cards: std.ArrayListUnmanaged(CommonCard),

pub fn deinit(cosmos: *Cosmos) void {
    for (cosmos.cards.items) |*card|
        card.deinit(cosmos.allocator);
    cosmos.cards.deinit(cosmos.allocator);
    cosmos.* = undefined;
}
