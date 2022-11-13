const std = @import("std");
const rl = @import("rl.zig");

pub fn main() void {
    rl.SetConfigFlags(rl.FLAG_WINDOW_RESIZABLE);
    rl.SetConfigFlags(rl.FLAG_MSAA_4X_HINT);
    rl.InitWindow(1366, 768, "[pablo's experimental vtt]");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);

    cosmos = .{};

    cosmos.dice_models.init();
    defer cosmos.dice_models.deinit();

    for (cosmos.dice_models.models) |*model| {
        model.transform = rl.MatrixIdentity();
        std.debug.print("Transform: {any}\n", .{@bitCast([4][4]f32, model.transform)});
    }

    rl.GuiSetFont(rl.LoadFont("c:/windows/fonts/segoeui.ttf"));

    rl.SetCameraMode(cosmos.scene.camera, rl.CAMERA_FREE);

    while (!rl.WindowShouldClose()) {
        rl.UpdateCamera(&cosmos.scene.camera);

        rl.BeginDrawing();
        defer rl.EndDrawing();
        rl.ClearBackground(rl.RAYWHITE);

        if (rl.GuiButton(rl.Rectangle.init(10, 10, 100, 32), "Roll d6")) {
            cosmos.display_the_frontier_seconds = 2.0;
        }

        draw_dice();
    }
}

fn draw_dice() void {
    rl.BeginMode3D(cosmos.scene.camera);
    defer rl.EndMode3D();

    const positions = [_]rl.Vector3{
        rl.Vector3.init(-4, 2, 0),
        rl.Vector3.init(0, 2, 0),
        rl.Vector3.init(4, 2, 0),
        rl.Vector3.init(-4, -2, 0),
        rl.Vector3.init(0, -2, 0),
        rl.Vector3.init(4, -2, 0),
    };

    for (positions[0..DiceType.len]) |position, i| {
        rl.DrawModel(cosmos.dice_models.models[i], position, 1.0, rl.BLACK);
    }
}

const Cosmos = struct {
    display_the_frontier_seconds: f32 = 0,
    scene: Scene = .{},
    dice_models: DiceModels = undefined,
};
var cosmos = @as(Cosmos, undefined);

const Scene = struct {
    camera: rl.Camera = .{
        .position = rl.Vector3.init(0, 0, 8),
        .target = rl.Vector3.init(0, 0, 0),
        .up = rl.Vector3.init(0, 1, 0),
        .fovy = 45,
        .projection = rl.CAMERA_PERSPECTIVE,
    },
};

const DiceType = enum {
    d4,
    d6,
    d8,
    d10,
    d12,
    d20,
    const len = @typeInfo(@This()).Enum.fields.len;
};

const DiceModels = struct {
    models: [DiceType.len]rl.Model,
    _textures: [DiceType.len]rl.Texture,

    fn init(dm: *DiceModels) void {
        inline for (@typeInfo(DiceType).Enum.fields) |field, i| {
            dm.models[i] = rl.LoadModel(std.fmt.comptimePrint("content/Dice/{s}.obj", .{field.name}));
            std.debug.assert(dm.models[i].meshCount == 1);
            dm._textures[i] = rl.LoadTexture(std.fmt.comptimePrint("content/Dice/{s}_Numbers.png", .{field.name}));
            dm.models[i].materials[0].maps[rl.MATERIAL_MAP_DIFFUSE].texture = dm._textures[i];
        }
    }

    fn deinit(dm: *DiceModels) void {
        for (dm.models) |model|
            rl.UnloadModel(model);
        for (dm._textures) |texture|
            rl.UnloadTexture(texture);
        dm.* = undefined;
    }
};
