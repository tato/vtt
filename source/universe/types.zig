const std = @import("std");

pub const CardIndex = usize;

pub fn StringEnumMap(comptime Enum: type) type {
    return std.ComptimeStringMap(Enum, blk: {
        var elems = @as([@typeInfo(Enum).Enum.fields.len]std.meta.Tuple(&.{ []const u8, Enum }), undefined);
        for (@typeInfo(Enum).Enum.fields) |field, idx| {
            elems[idx] = .{ field.name, @field(Enum, field.name) };
        }
        break :blk elems;
    });
}
