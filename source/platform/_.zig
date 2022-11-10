const std = @import("std");
pub const rl = @import("raylib");

pub fn main(
    comptime State: type,
    comptime init_function: fn (std.mem.Allocator, *State) void,
    comptime update_function: fn (*State) void,
    comptime cleanup_function: fn (*State) void,
) fn () void {
    return struct {
        fn _main() void {
            var gpa = std.heap.GeneralPurposeAllocator(.{}){};
            defer std.debug.assert(!gpa.deinit());

            rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
            rl.InitWindow(1366, 968, "vTT");
            rl.SetTargetFPS(60);

            var state = @as(State, undefined);
            init_function(gpa.allocator(), &state);
            defer cleanup_function(&state);

            while (!rl.WindowShouldClose()) {
                update_function(&state);
            }
        }
    }._main;
}

pub fn get_screen_width(comptime T: type) T {
    return std.math.lossyCast(T, rl.GetScreenWidth());
}

pub fn get_screen_height(comptime T: type) T {
    return std.math.lossyCast(T, rl.GetScreenHeight());
}
