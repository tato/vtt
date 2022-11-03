const std = @import("std");

const FileReader = @This();
source: []const u8,
current: usize = 0,

pub fn next(reader: *FileReader) ?[]const u8 {
    reader.advanceWhile(isSpace);

    const start = reader.current;
    reader.advanceWhile(isNotSpace);
    const end = reader.current;

    if (end == start)
        return null;

    reader.advanceWhile(isSpace);

    return reader.source[start..end];
}

pub fn readToEndOfLine(reader: *FileReader) ?[]const u8 {
    reader.advanceWhile(isEol);

    const start = reader.current;
    reader.advanceWhile(isNotEol);
    const end = reader.current;

    if (end == start)
        return null;

    reader.advanceWhile(isEol);

    return reader.source[start..end];
}

pub fn nextInt(reader: *FileReader, comptime Int: type) ?std.fmt.ParseIntError!Int {
    comptime std.debug.assert(@typeInfo(Int) == .Int);
    const word = reader.next() orelse return null;
    return std.fmt.parseInt(Int, word, 10);
}

pub fn nextFloat(reader: *FileReader, comptime Float: type) ?std.fmt.ParseFloatError!Float {
    comptime std.debug.assert(@typeInfo(Float) == .Float);
    const word = reader.next() orelse return null;
    return std.fmt.parseFloat(Float, word);
}

fn advanceWhile(reader: *FileReader, comptime condition: fn (u8) bool) void {
    while (reader.current < reader.source.len and condition(reader.source[reader.current])) {
        reader.current += 1;
    }
}

const isSpace = std.ascii.isSpace;
fn isNotSpace(c: u8) bool {
    return !std.ascii.isSpace(c);
}
fn isEol(c: u8) bool {
    return c == '\r' or c == '\n';
}
fn isNotEol(c: u8) bool {
    return c != '\r' and c != '\n';
}

test next {
    var reader = FileReader{ .source = "Unbowed, unbent, unbroken." };
    try std.testing.expectEqualStrings("Unbowed,", reader.next() orelse "?");
    try std.testing.expectEqualStrings("unbent,", reader.next() orelse "?");
    try std.testing.expectEqualStrings("unbroken.", reader.next() orelse "?");
}

test readToEndOfLine {
    var reader = FileReader{
        .source = 
        \\We light the way.
        \\Though all men do despise us.
        \\Unbowed, unbent, unbroken.
        ,
    };
    try std.testing.expectEqualStrings("We light the way.", reader.readToEndOfLine() orelse "?");
    try std.testing.expectEqualStrings("Though all men do despise us.", reader.readToEndOfLine() orelse "?");
    try std.testing.expectEqualStrings("Unbowed,", reader.next() orelse "?");
    try std.testing.expectEqualStrings("unbent, unbroken.", reader.readToEndOfLine() orelse "?");
}

test nextInt {
    var reader = FileReader{ .source = "1 Awake! 2" };
    try std.testing.expectEqual(@as(?anyerror!i64, 1), reader.nextInt(i64));
    try std.testing.expectEqual(@as(?anyerror!i64, error.InvalidCharacter), reader.nextInt(i64));
    try std.testing.expectEqual(@as(?anyerror!u8, 2), reader.nextInt(u8));
}

test nextFloat {
    var reader = FileReader{ .source = "1.0 Awake! 2.0" };
    try std.testing.expectEqual(@as(?anyerror!f64, 1.0), reader.nextFloat(f64));
    try std.testing.expectEqual(@as(?anyerror!f64, error.InvalidCharacter), reader.nextFloat(f64));
    try std.testing.expectEqual(@as(?anyerror!f32, 2.0), reader.nextFloat(f32));
}
