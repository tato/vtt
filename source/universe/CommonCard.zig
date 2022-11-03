const std = @import("std");

const FileReader = @import("FileReader.zig");

const CommonCard = @This();
unique_id: []const u8,
name: []const u8,
icon_uri: ?[]const u8,
position: [2]f64,
child_tabs: std.ArrayListUnmanaged(usize),

pub fn deinit(card: *CommonCard, allocator: std.mem.Allocator) void {
    allocator.free(card.unique_id);
    allocator.free(card.name);
    if (card.icon_uri) |icon_uri| allocator.free(icon_uri);
    card.* = undefined;
}

pub fn format(card: CommonCard, comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: anytype) !void {
    _ = fmt;
    _ = options;
    try writer.print(
        "CommonCard{{\n\tunique_id = \"{s}\",\n\tname = \"{s}\"",
        .{ card.unique_id, card.name },
    );
    if (card.icon_uri) |icon_uri| {
        try writer.print(",\n\ticon_uri = \"{s}\"", .{icon_uri});
    }
    try writer.print(
        ",\n\tposition = [{d:.2}, {d:.2}]",
        .{ card.position[0], card.position[1] },
    );
    try writer.writeAll("\n}}");
}

pub fn read(card: *CommonCard, allocator: std.mem.Allocator, reader: *FileReader) !void {
    while (reader.next()) |word| {
        if (std.mem.eql(u8, "icon", word)) {
            const icon_uri = reader.readToEndOfLine() orelse return error.stream_too_small;
            card.icon_uri = try allocator.dupe(u8, icon_uri);
        } else if (std.mem.eql(u8, "position", word)) {
            const x = try (reader.nextFloat(f64) orelse error.stream_too_small);
            const y = try (reader.nextFloat(f64) orelse error.stream_too_small);
            card.position = .{ x, y };
        }
    }
}
