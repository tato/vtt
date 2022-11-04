const std = @import("std");

pub const Universe = @import("universe/Universe.zig");
const CommonCard = @import("universe/CommonCard.zig");
const FileReader = @import("universe/FileReader.zig");

pub fn read_from_directory(allocator: std.mem.Allocator, d: std.fs.IterableDir) !Universe {
    var walker = try d.walk(allocator);
    defer walker.deinit();

    var cards = std.ArrayList(CommonCard).init(allocator);
    var card_parents = std.AutoHashMap(Universe.CardIndex, []const u8).init(allocator);
    defer {
        var i = card_parents.valueIterator();
        while (i.next()) |value| allocator.free(value.*);
        card_parents.deinit();
    }

    while (try walker.next()) |entry| {
        if (entry.kind == .Directory)
            continue;

        const id_extension_index = std.mem.lastIndexOfScalar(u8, entry.path, '.') orelse entry.path.len;
        const unique_id = try allocator.dupe(u8, entry.path[0..id_extension_index]);

        const name_extension_index = std.mem.lastIndexOfScalar(u8, entry.basename, '.') orelse entry.basename.len;
        const name = try allocator.dupe(u8, entry.basename[0..name_extension_index]);

        try cards.append(std.mem.zeroInit(CommonCard, .{
            .unique_id = unique_id,
            .name = name,
        }));

        if (get_parent_id_from_path(entry.path)) |parent_id| {
            const id = try allocator.dupe(u8, parent_id);
            try card_parents.put(cards.items.len - 1, id);
        }

        const source = try d.dir.readFileAlloc(allocator, entry.path, 1 << 30);
        defer allocator.free(source);

        var reader = FileReader{ .source = source };
        try cards.items[cards.items.len - 1].read(allocator, &reader);

        reader.current = 0;
        if (get_card_kind(&reader)) |kind| {
            if (std.mem.eql(u8, "sheet_v1", kind)) {
                //
            }
        }
    }

    var card_parents_iterator = card_parents.iterator();
    while (card_parents_iterator.next()) |entry| {
        for (cards.items) |*card| {
            if (std.mem.eql(u8, card.unique_id, entry.value_ptr.*)) {
                try card.child_tabs.append(allocator, entry.key_ptr.*);
                break;
            }
        } else std.debug.panic("The parent id [{s}] is not present.", .{entry.value_ptr.*});
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

fn get_card_kind(reader: *FileReader) ?[]const u8 {
    return while (reader.next()) |word| {
        if (std.mem.eql(u8, "kind", word)) {
            const kind = reader.next() orelse break null;
            break kind;
        }
    } else null;
}

fn get_parent_id_from_path(path: []const u8) ?[]const u8 {
    return std.fs.path.dirname(path);
}
