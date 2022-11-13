const std = @import("std");
const cosmos = @import("cosmos");
const platform = @import("platform");
const Ui = @import("ui").Ui;

pub const main = platform.main(App, init, update, cleanup);

fn init(allocator: std.mem.Allocator, app: *App) void {
    app.ui = allocator.create(Ui) catch @panic("out of memory");
    app.ui.* = Ui.init(allocator);
    app.ui.font = platform.rl.LoadFont("c:/windows/fonts/segoeui.ttf");

    load_world_from_file(allocator, app);
}

fn update(app: *App) void {
    const ui = app.ui;

    ui.begin();
    defer ui.end();

    // if (app.reload_next_frame) {
    //     const allocator = app.main_allocator;
    //     app.deinit();
    //     load_world_from_file(allocator, app);
    // }

    // if (app.dragging != App.not_dragging) {
    //     const rl = @import("raylib"); // 🤫
    //     const dragging = &app.tokens.items[app.dragging];
    //     dragging.left += rl.GetMouseDelta().x;
    //     dragging.top += rl.GetMouseDelta().y;

    //     if (rl.IsMouseButtonUp(rl.MOUSE_BUTTON_LEFT)) {
    //         app.dragging = App.not_dragging;
    //     }
    // }

    // for (app.cosmos.cards.items) |card, card_idx| {
    //     ui.push_parent(ui.layout_positioned("", @floatCast(f32, card.position[0]), @floatCast(f32, card.position[1])));
    //     defer ui.pop_parent();

    //     if (ui.paint_button(card.name)) {
    //         app.dragging = @intCast(u32, card_idx);
    //     }
    //     ui.last_inserted.semantic_size[0] = .{ .kind = .pixels, .value = 150 };
    //     ui.last_inserted.semantic_size[1] = .{ .kind = .pixels, .value = 150 };
    //     ui.last_inserted.elevation = 1;
    // }
    // draw_funny(app, ui);

    // ui.push_parent(ui.layout_positioned("", 10, 10));
    // if (ui.paint_button("cargar")) {
    //     app.reload_next_frame = true;
    // }
    // _ = ui.block_layout("_padding", .x);
    // ui.last_inserted.semantic_size[0].kind = .pixels;
    // ui.last_inserted.semantic_size[0].value = 16;
    // if (ui.paint_button("guardar")) {
    //     //
    // }
    // ui.pop_parent();
}

fn cleanup(app: *App) void {
    app.deinit();
}

const App = struct {
    main_allocator: std.mem.Allocator,
    ui: *Ui,
    dragging: u32 = not_dragging,
    reload_next_frame: bool = false,
    cosmos: cosmos.Cosmos,

    const not_dragging = std.math.maxInt(u32);

    fn deinit(app: *App) void {
        app.ui.deinit();
        app.main_allocator.destroy(app.ui);

        app.cosmos.deinit();

        app.* = undefined;
    }
};

fn load_world_from_file(allocator: std.mem.Allocator, app: *App) void {
    const ui = app.ui;
    app.* = .{
        .main_allocator = allocator,
        .cosmos = undefined,
        .ui = ui,
    };

    const d = std.fs.cwd().openIterableDir("sample", .{}) catch @panic("Can't open directory.");
    app.cosmos = cosmos.read_from_directory(allocator, d) catch @panic("Something happened.");
}

fn draw_funny(app: *App, ui: *Ui) void {
    if (ui.paint_button("funny")) {
        _ = app;
        // app.dragging = @intCast(u32, token_idx);
    }
    ui.last_inserted.semantic_size[0] = .{ .kind = .pixels, .value = 400 };
    ui.last_inserted.semantic_size[1] = .{ .kind = .pixels, .value = 300 };
    ui.last_inserted.elevation = 1;
}
