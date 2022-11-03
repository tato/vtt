const std = @import("std");
const rl = @import("raylib");
const Ui = @import("Ui.zig");

pub fn main(
    comptime State: type,
    comptime init_function: fn (std.mem.Allocator, *State) void,
    comptime update_function: fn (*State, *Ui) void,
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

            var ui = Ui.init(gpa.allocator());
            defer ui.deinit(gpa.allocator());
            ui.font = rl.LoadFont("c:/windows/fonts/segoeui.ttf");

            while (!rl.WindowShouldClose()) {
                ui.begin();
                defer ui.end();

                update_function(&state, &ui);
            }
        }
    }._main;
}
