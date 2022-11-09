pub const rl = @import("raylib");

pub fn create_window(title: [:0]const u8) void {
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
    rl.InitWindow(1366, 968, title.ptr);
    rl.SetTargetFPS(60);
}

pub fn main_loop(
    comptime update_function: fn () void,
    comptime paint_function: fn () void,
) void {
    while (!rl.WindowShouldClose()) {
        update_function();

        rl.BeginDrawing();
        rl.ClearBackground(rl.WHITE);

        paint_function();

        rl.EndDrawing();
    }
}
