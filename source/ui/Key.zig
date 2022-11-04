const std = @import("std");

const Key = @This();
string: []const u8,
hash: u64,

pub fn init(string: []const u8) Key {
    return .{
        .string = string,
        .hash = std.hash.Wyhash.hash(413, string),
    };
}

pub fn dupe(allocator: std.mem.Allocator, string: []const u8) !Key {
    return .{
        .string = try allocator.dupe(u8, string),
        .hash = std.hash.Wyhash.hash(413, string),
    };
}

pub const HashContext = struct {
    pub fn hash(_: HashContext, key: Key) u64 {
        return key.hash;
    }
    pub fn eql(_: HashContext, a: Key, b: Key) bool {
        return a.hash == b.hash and std.mem.eql(u8, a.string, b.string);
    }
};
