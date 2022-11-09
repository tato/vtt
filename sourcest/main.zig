const std = @import("std");
const cosmos = @import("cosmos.zig");
const platform = @import("platform.zig");

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(!gpa.deinit());

    platform.create_window("we light the way");

    cosmos.init(gpa.allocator());
    defer cosmos.deinit();

    // var ui = Ui.init(gpa.allocator());
    // defer ui.deinit(gpa.allocator());
    // ui.font = rl.LoadFont("c:/windows/fonts/segoeui.ttf");

    platform.main_loop(cosmos.update, cosmos.paint);
}
