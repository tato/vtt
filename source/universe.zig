const std = @import("std");

pub const Universe = @import("universe/Universe.zig");
const GenericCard = @import("universe/GenericCard.zig");

pub fn read_from_directory(allocator: std.mem.Allocator, d: std.fs.IterableDir) !Universe {
    var i = try d.walk(allocator);
    defer i.deinit();

    var cards = std.ArrayList(GenericCard).init(allocator);
    while (try i.next()) |entry| {
        if (entry.kind == .Directory)
            continue;

        const extension_index = std.mem.lastIndexOfScalar(u8, entry.basename, '.') orelse entry.basename.len;

        const unique_id = try allocator.dupe(u8, entry.path);
        const name = try allocator.dupe(u8, entry.basename[0..extension_index]);

        try cards.append(std.mem.zeroInit(GenericCard, .{
            .unique_id = unique_id,
            .name = name,
        }));
    }

    return Universe{
        .allocator = allocator,
        .cards = cards.moveToUnmanaged(),
    };
}

test read_from_directory {
    var d = try std.fs.cwd().openIterableDir("sample", .{});
    defer d.close();

    var uni = try read_from_directory(std.testing.allocator, d);
    defer uni.deinit();

    std.debug.print("{d} items\n", .{uni.cards.items.len});
    for (uni.cards.items) |card| std.debug.print("{any}\n", .{card});
}
