const std = @import("std");
const rl = @import("raylib");
pub const Ui = @import("platform/Ui.zig");

pub fn main(
    comptime State: type,
    comptime init_function: fn (std.mem.Allocator, *State) void,
    comptime update_function: fn (*State, *Ui) void,
    comptime cleanup_function: fn (std.mem.Allocator, *State) void,
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
            defer cleanup_function(gpa.allocator(), &state);

            var ui = Ui.init(gpa.allocator());
            defer ui.deinit(gpa.allocator());
            ui.font = rl.LoadFont("c:/windows/fonts/arial.ttf");

            while (!rl.WindowShouldClose()) {
                ui.begin();
                defer ui.end();

                update_function(&state, &ui);
            }
        }
    }._main;
}

fn draw_rounded_rect(rect: rl.Rectangle, thick: f32, radius: f32, color: rl.Color) void {
    _ = thick;

    const steps = 8;
    const required_capacity = (steps + 1) * 4 + 5;
    var points = std.BoundedArray(rl.Vector2, required_capacity).init();

    for (@as([*]void, undefined)[0 .. steps + 1]) |_, i| {
        const x0 = rect.x + radius;
        const y0 = rect.y + radius;
        rl.DrawCircleV(rl.Vector2.init(x0, y0), 1, rl.RED);
        const ang = std.math.pi / 2.0 / steps * @intToFloat(f32, i);
        const x = x0 + radius * @cos(ang + std.math.pi);
        const y = y0 + radius * @sin(ang + std.math.pi);
        points.appendAssumeCapacity(rl.Vector2.init(x, y));
    }
    for (@as([*]void, undefined)[0 .. steps + 1]) |_, i| {
        const x0 = rect.x + rect.width - radius;
        const y0 = rect.y + radius;
        rl.DrawCircleV(rl.Vector2.init(x0, y0), 1, rl.RED);
        const ang = std.math.pi / 2.0 / steps * @intToFloat(f32, i);
        const x = x0 + radius * @cos(ang - std.math.pi / 2.0);
        const y = y0 + radius * @sin(ang - std.math.pi / 2.0);
        points.appendAssumeCapacity(rl.Vector2.init(x, y));
    }
    for (@as([*]void, undefined)[0 .. steps + 1]) |_, i| {
        const x0 = rect.x + rect.width - radius;
        const y0 = rect.y + rect.height - radius;
        const ang = std.math.pi / 2.0 / steps * @intToFloat(f32, i);
        const x = x0 + radius * @cos(ang);
        const y = y0 + radius * @sin(ang);
        std.debug.print("{d} -> {d:.4} ({d:.4})\n", .{ i, ang, std.math.pi / 2.0 });
        points.appendAssumeCapacity(rl.Vector2.init(x, y));
    }
    for (@as([*]void, undefined)[0 .. steps + 1]) |_, i| {
        const x0 = rect.x + radius;
        const y0 = rect.y + rect.height - radius;
        const ang = std.math.pi / 2.0 / steps * @intToFloat(f32, i);
        const x = x0 + radius * @cos(ang + std.math.pi / 2.0);
        const y = y0 + radius * @sin(ang + std.math.pi / 2.0);
        points.appendAssumeCapacity(rl.Vector2.init(x, y));
    }
    points.appendAssumeCapacity(rl.Vector2.init(rect.x, rect.y + radius));

    rl.DrawLineStrip(points.slice(), color);
}
