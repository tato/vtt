const std = @import("std");
const toml = @import("toml");
const platform = @import("platform.zig");

pub const main = platform.main(World, init, update, cleanup);

fn init(allocator: std.mem.Allocator, world: *World) void {
    const file = get_sample_world_file(allocator) catch |e| {
        std.debug.print("{any}\n", .{@errorReturnTrace()});
        std.debug.panic("({!}) Sample project file could not be read.", .{e});
    };
    defer toml_free(WorldFile, allocator, file);

    world.* = World.from_file(allocator, file) catch @panic("Out of memory.");
}

fn update(world: *World, ui: *platform.Ui) void {
    if (world.dragging != World.not_dragging) {
        const rl = @import("raylib"); // 🤫
        const dragging = &world.tokens.items[world.dragging];
        dragging.left += rl.GetMouseDelta().x;
        dragging.top += rl.GetMouseDelta().y;

        if (rl.IsMouseButtonUp(rl.MOUSE_BUTTON_LEFT)) {
            world.dragging = World.not_dragging;
        }
    }

    for (world.tokens.items) |token, token_idx| {
        ui.push_parent(ui.layout_positioned(token.left, token.top));
        defer ui.pop_parent();

        if (ui.button(token.name)) {
            world.dragging = @intCast(u32, token_idx);
        }
    }
}

fn cleanup(allocator: std.mem.Allocator, world: *World) void {
    world.deinit(allocator);
}

const World = struct {
    tokens: std.ArrayList(Token),
    dragging: u32 = not_dragging,

    const not_dragging = std.math.maxInt(u32);

    fn from_file(allocator: std.mem.Allocator, file: WorldFile) !World {
        var tokens = try std.ArrayList(Token).initCapacity(allocator, file.tokens.len);
        for (file.tokens) |token| {
            tokens.appendAssumeCapacity(try Token.from_file(allocator, token));
        }
        return World{
            .tokens = tokens,
        };
    }

    fn deinit(world: *World, allocator: std.mem.Allocator) void {
        for (world.tokens.items) |*token| token.deinit(allocator);
        world.tokens.deinit();
        world.* = undefined;
    }
};
const Token = struct {
    name: [:0]const u8,
    details: [:0]const u8,
    left: f32 = 0,
    top: f32 = 0,

    fn from_file(allocator: std.mem.Allocator, file: TokenFile) !Token {
        return Token{
            .name = try allocator.dupeZ(u8, file.name),
            .details = try allocator.dupeZ(u8, file.details),
            .left = @intToFloat(f32, file.position[0]),
            .top = @intToFloat(f32, file.position[1]),
        };
    }

    fn deinit(token: *Token, allocator: std.mem.Allocator) void {
        allocator.free(token.name);
        allocator.free(token.details);
        token.* = undefined;
    }
};
const WorldFile = struct {
    tokens: []const TokenFile,
};
const TokenFile = struct {
    name: []const u8,
    details: []const u8,
    position: [2]i64,
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
