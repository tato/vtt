const std = @import("std");

const BlockLabel = @This();
key_part: []const u8,
label_part: []const u8,

pub fn parse(string: []const u8) BlockLabel {
    var result = BlockLabel{
        .key_part = string,
        .label_part = string,
    };

    var i = std.mem.split(u8, string, "###");
    const first = i.next().?;
    if (first.len != string.len) {
        result.key_part = first;
        result.label_part = i.next().?;
        std.debug.assert(i.next() == null);
        return result;
    }

    if (std.mem.indexOf(u8, string, "##")) |index| {
        result.label_part = string[0..index];
    }
    return result;
}
