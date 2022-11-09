const std = @import("std");
const toml = @import("toml");
const platform = @import("platform.zig");
const uni = @import("universe.zig");
const Ui = @import("ui.zig").Ui;

pub const main = platform.main(World, init, update, cleanup);

fn init(allocator: std.mem.Allocator, world: *World) void {
    load_world_from_file(allocator, world);
}

fn update(world: *World, ui: *Ui) void {
    if (world.reload_next_frame) {
        const allocator = world.main_allocator;
        world.deinit();
        load_world_from_file(allocator, world);
    }

    // if (world.dragging != World.not_dragging) {
    //     const rl = @import("raylib"); // 🤫
    //     const dragging = &world.tokens.items[world.dragging];
    //     dragging.left += rl.GetMouseDelta().x;
    //     dragging.top += rl.GetMouseDelta().y;

    //     if (rl.IsMouseButtonUp(rl.MOUSE_BUTTON_LEFT)) {
    //         world.dragging = World.not_dragging;
    //     }
    // }

    for (world.universe.cards.items) |card, card_idx| {
        // std.debug.print("hehe [{d:.2}, {d:.2}]\n", .{ card.position[0], card.position[1] });
        // ui.push_parent(ui.layout_positioned("", @floatCast(f32, card.position[0]), @floatCast(f32, card.position[1])));
        // defer ui.pop_parent();

        if (ui.do_button(card.name)) {
            world.dragging = @intCast(u32, card_idx);
        }
        ui.last_inserted.semantic_size[0] = .{ .kind = .pixels, .value = 150 };
        ui.last_inserted.semantic_size[1] = .{ .kind = .pixels, .value = 150 };
        ui.last_inserted.elevation = 1;
    }
    // draw_funny(world, ui);

    // ui.push_parent(ui.layout_positioned("", 10, 10));
    // if (ui.do_button("cargar")) {
    //     world.reload_next_frame = true;
    // }
    // _ = ui.block_layout("_padding", .x);
    // ui.last_inserted.semantic_size[0].kind = .pixels;
    // ui.last_inserted.semantic_size[0].value = 16;
    // if (ui.do_button("guardar")) {
    //     //
    // }
    // ui.pop_parent();
}

fn cleanup(world: *World) void {
    world.deinit();
}

const World = struct {
    main_allocator: std.mem.Allocator,
    dragging: u32 = not_dragging,
    reload_next_frame: bool = false,
    universe: uni.Universe,

    const not_dragging = std.math.maxInt(u32);

    fn deinit(world: *World) void {
        world.universe.deinit();
        world.* = undefined;
    }
};

// const Token = struct {
//     name: [:0]const u8,
//     details: [:0]const u8,
//     left: f32 = 0,
//     top: f32 = 0,

//     fn from_file(allocator: std.mem.Allocator, file: TokenFile) !Token {
//         return Token{
//             .name = try allocator.dupeZ(u8, file.name),
//             .details = try allocator.dupeZ(u8, file.details),
//             .left = @intToFloat(f32, file.position[0]),
//             .top = @intToFloat(f32, file.position[1]),
//         };
//     }

//     fn deinit(token: *Token, allocator: std.mem.Allocator) void {
//         allocator.free(token.name);
//         allocator.free(token.details);
//         token.* = undefined;
//     }
// };
// const WorldFile = struct {
//     tokens: []const TokenFile,
// };
// const TokenFile = struct {
//     name: []const u8,
//     details: []const u8,
//     position: [2]i64,
// };

fn load_world_from_file(allocator: std.mem.Allocator, world: *World) void {
    world.* = .{
        .main_allocator = allocator,
        .universe = undefined,
    };

    const d = std.fs.cwd().openIterableDir("sample", .{}) catch @panic("Can't open directory.");
    world.universe = uni.read_from_directory(allocator, d) catch @panic("Something happened.");
}

fn draw_funny(world: *World, ui: *Ui) void {
    if (ui.do_button("funny")) {
        _ = world;
        // world.dragging = @intCast(u32, token_idx);
    }
    ui.last_inserted.semantic_size[0] = .{ .kind = .pixels, .value = 400 };
    ui.last_inserted.semantic_size[1] = .{ .kind = .pixels, .value = 300 };
    ui.last_inserted.elevation = 1;
}
