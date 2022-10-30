const std = @import("std");
const toml = @import("toml");
const platform = @import("platform.zig");

pub const main = platform.main(World, init, update);

fn init(allocator: std.mem.Allocator, world: *World) void {
    const file = get_sample_world_file(allocator) catch |e| {
        std.debug.print("{any}\n", .{@errorReturnTrace()});
        std.debug.panic("({!}) Sample project file could not be read.", .{e});
    };

    world.* = .{
        .file = file,
    };
}

fn update(world: *World, ui: *platform.Ui) void {
    var x = @as(f32, 200);
    for (world.file.tokens) |token| {
        ui.push_parent(ui.layout_positioned(x, 300));
        defer ui.pop_parent();
        ui.label(token.name);
        x += 200;
    }
}

const World = struct {
    file: WorldFile,
};
const WorldFile = struct {
    tokens: []const TokenFile,
};
const TokenFile = struct {
    name: [:0]const u8,
    details: [:0]const u8,
};

fn get_sample_world_file(allocator: std.mem.Allocator) !WorldFile {
    const file = try std.fs.cwd().readFileAlloc(allocator, "sample/world.toml", 1 << 30);
    defer allocator.free(file);
    return try toml.parse(WorldFile, allocator, file);
}

test {
    const allocator = std.testing.allocator;

    const buffer = try std.fs.cwd().readFileAlloc(allocator, "sample/world.toml", 1 << 30);
    defer allocator.free(buffer);

    const world = try toml.parse(WorldFile, allocator, buffer);
    defer toml_free(WorldFile, allocator, world);

    std.debug.print("We light the way:\n{any}\n", .{world});
}

fn toml_free(comptime T: type, allocator: std.mem.Allocator, value: T) void {
    switch (@typeInfo(T)) {
        .Struct => {
            inline for (@typeInfo(T).Struct.fields) |field| {
                switch (@typeInfo(field.field_type)) {
                    .Pointer => {
                        if (@typeInfo(@typeInfo(field.field_type).Pointer.child) == .Struct) {
                            for (@field(value, field.name)) |elem| {
                                toml_free(@TypeOf(elem), allocator, elem);
                            }
                        }
                        allocator.free(@field(value, field.name));
                    },
                    .Struct => {
                        toml_free(field.field_type, allocator, @field(value, field.name));
                    },
                    else => {},
                }
            }
        },
        else => unreachable,
    }
}
