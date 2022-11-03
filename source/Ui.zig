const std = @import("std");
const rl = @import("raylib");

const Ui = @This();
gpa: std.mem.Allocator,
arena: std.heap.ArenaAllocator,

frame_index: u64 = 0,
blocks: BlockMap = .{},

primordial_parent: *Block,
current_parent: *Block,
last_inserted: *Block,

font: rl.Font,

const BlockMap = std.HashMapUnmanaged(Key, *Block, KeyHashContext, 80);

const Block = struct {
    // tree links
    first: ?*Block,
    last: ?*Block,
    next: ?*Block,
    prev: ?*Block,
    parent: ?*Block,

    // key+generation info
    key: Key,
    last_frame_touched_index: u64,

    // per-frame info provided by builders
    flags: BlockFlags,
    string: ?[:0]const u8,
    semantic_size: [Axis.len]Size,
    layout_axis: Axis = .x,
    background_color: u32 = 0x00_00_00_00,
    elevation: u8 = 0,

    // computed every frame
    computed_rel_position: [Axis.len]f32,
    computed_size: [Axis.len]f32,
    rect: rl.Rectangle,

    // persistent data
    hot_t: f32 = 0,
    active_t: f32 = 0,

    pub fn clear_per_frame_info(block: *Block) void {
        block.flags = .{};
        block.string = null;
        block.semantic_size[0] = .{ .kind = .text_content, .value = 0, .strictness = 0 };
        block.semantic_size[1] = .{ .kind = .text_content, .value = 0, .strictness = 0 };
        block.layout_axis = .x;
        block.background_color = 0x00_00_00_00;

        block.first = null;
        block.last = null;
        block.next = null;
        block.prev = null;
        block.parent = null;
    }
};

const BlockFlags = packed struct {
    border: bool = false,
    positioned: bool = false,
    _padding: u30 = 0,

    comptime {
        std.debug.assert(@bitSizeOf(BlockFlags) == 32);
    }
};

const SizeKind = enum {
    pixels,
    text_content,
    percent_of_parent,
    children_sum,
};

pub const Size = struct {
    kind: SizeKind,
    value: f32,
    strictness: f32 = 1,

    pub fn init(kind: SizeKind, value: f32, strictness: f32) Size {
        std.debug.assert(value >= 0);
        std.debug.assert(strictness >= 0 and strictness <= 1);
        return Size{ .kind = kind, .value = value, .strictness = strictness };
    }
};

const Axis = enum {
    x,
    y,
    const len = @typeInfo(Axis).Enum.fields.len;
};

pub fn init(gpa: std.mem.Allocator) Ui {
    const primordial_parent = gpa.create(Block) catch @panic("Out of memory.");
    primordial_parent.* = std.mem.zeroes(Block);
    return .{
        .gpa = gpa,
        .arena = undefined,
        .primordial_parent = primordial_parent,
        .current_parent = primordial_parent,
        .last_inserted = primordial_parent,
        .font = rl.GetFontDefault(),
    };
}

pub fn deinit(ui: *Ui, allocator: std.mem.Allocator) void {
    std.debug.assert(allocator.ptr == ui.gpa.ptr);
    ui.gpa.destroy(ui.primordial_parent);
    var i = ui.blocks.valueIterator();
    while (i.next()) |block| ui.gpa.destroy(block.*);
    ui.blocks.deinit(ui.gpa);
    ui.* = undefined;
}

pub fn begin(ui: *Ui) void {
    ui.frame_index += 1;
    ui.current_parent = ui.primordial_parent;

    ui.arena = std.heap.ArenaAllocator.init(ui.gpa);

    ui.primordial_parent.clear_per_frame_info();
    const semantic_size = Size{ .kind = .percent_of_parent, .value = 1, .strictness = 1 };
    ui.primordial_parent.semantic_size[0] = semantic_size;
    ui.primordial_parent.semantic_size[1] = semantic_size;
    ui.primordial_parent.computed_size = .{ @intToFloat(f32, rl.GetScreenWidth()), @intToFloat(f32, rl.GetScreenHeight()) };
    ui.primordial_parent.computed_rel_position = .{ 0, 0 };
    ui.primordial_parent.rect = rl.Rectangle.init(0, 0, ui.primordial_parent.computed_size[0], ui.primordial_parent.computed_size[1]);
}

pub fn end(ui: *Ui) void {
    calculate_standalone_sizes(ui.primordial_parent, ui.font);
    calculate_upward_dependent_sizes(ui.primordial_parent);
    calculate_downward_dependent_sizes(ui.primordial_parent);
    solve_violations(ui.primordial_parent);
    compute_relative_positions(ui.primordial_parent);

    rl.BeginDrawing();
    rl.ClearBackground(rl.Color.init(0xf3, 0xf3, 0xf3, 0xff));

    ui.render_tree(ui.primordial_parent);

    rl.EndDrawing();

    ui.prune_widgets();

    ui.arena.deinit();
}

pub fn push_parent(ui: *Ui, block: *Block) void {
    ui.current_parent = block;
}

pub fn pop_parent(ui: *Ui) void {
    ui.current_parent = ui.current_parent.parent.?;
}

pub fn do_label(ui: *Ui, string: []const u8) void {
    const block = ui.get_or_insert_block(key_from_string(string));

    block.string = ui.arena.allocator().dupeZ(u8, string) catch string;
    block.semantic_size[@enumToInt(Axis.x)].kind = .text_content;
    block.semantic_size[@enumToInt(Axis.y)].kind = .text_content;
}

pub fn do_button(ui: *Ui, string: [:0]const u8) bool {
    const block = ui.get_or_insert_block(key_from_string(string));

    block.string = ui.arena.allocator().dupeZ(u8, string) catch string;
    block.semantic_size[@enumToInt(Axis.x)] = Size.init(.text_content, 1, 1);
    block.semantic_size[@enumToInt(Axis.y)] = Size.init(.text_content, 1, 1);
    block.background_color = 0xfa_fa_fa_ff;
    block.flags.border = true;

    const mouse_position = rl.GetMousePosition();
    return rl.CheckCollisionPointRec(mouse_position, block.rect) and rl.IsMouseButtonPressed(rl.MOUSE_BUTTON_LEFT);
}

pub fn block_layout(ui: *Ui, comptime string: [:0]const u8, axis: Axis) *Block {
    const block = ui.get_or_insert_block(key_from_string(string));

    block.semantic_size[@enumToInt(Axis.x)].kind = .children_sum;
    block.semantic_size[@enumToInt(Axis.y)].kind = .children_sum;
    block.layout_axis = axis;

    return block;
}

pub fn layout_positioned(ui: *Ui, left: f32, top: f32) *Block {
    const block = ui.get_or_insert_block(key_random());
    block.flags.positioned = true;

    block.semantic_size[@enumToInt(Axis.x)].kind = .children_sum;
    block.semantic_size[@enumToInt(Axis.y)].kind = .children_sum;
    block.layout_axis = .x;
    block.computed_rel_position[@enumToInt(Axis.x)] = left;
    block.computed_rel_position[@enumToInt(Axis.y)] = top;

    return block;
}

fn get_or_insert_block(ui: *Ui, key: Key) *Block {
    const entry = ui.blocks.getOrPut(ui.gpa, key) catch @panic("Out of memory.");
    if (!entry.found_existing) {
        const block = ui.gpa.create(Block) catch @panic("Out of memory.");
        block.* = std.mem.zeroInit(Block, .{
            .key = key,
        });
        entry.value_ptr.* = block;
    }

    const block = entry.value_ptr.*;
    block.clear_per_frame_info();

    block.prev = ui.current_parent.last;
    block.parent = ui.current_parent;

    if (block.prev) |previous_sibling| previous_sibling.next = block;

    if (ui.current_parent.first == null) ui.current_parent.first = block;
    ui.current_parent.last = block;

    block.last_frame_touched_index = ui.frame_index;
    ui.last_inserted = block;

    return block;
}

fn prune_widgets(ui: *Ui) void {
    var remove_blocks = std.ArrayList(Key).init(ui.arena.allocator());
    defer remove_blocks.deinit();

    var blocks_iterator = ui.blocks.iterator();
    while (blocks_iterator.next()) |entry| {
        if (entry.value_ptr.*.last_frame_touched_index < ui.frame_index) {
            ui.gpa.destroy(entry.value_ptr.*);
            remove_blocks.append(entry.key_ptr.*) catch {
                std.log.warn("prune_widgets: Out of memory.", .{});
                break;
            };
        }
    }

    for (remove_blocks.items) |key| _ = ui.blocks.remove(key);
}

const BlockLabel = struct {
    key_part: []const u8,
    label_part: []const u8,

    fn parse(string: []const u8) BlockLabel {
        var result = BlockLabel{
            .key_part = string,
            .label_part = string,
        };

        var i = std.mem.split(u8, string, "###");
        const first = i.next().?;
        if (first.len != string.len) {
            result.key_part = first;
            result.label_part = i.next().?;
            std.debug.assert(i.next() == null);
            return result;
        }

        if (std.mem.indexOf(u8, string, "##")) |index| {
            result.label_part = string[0..index];
        }
        return result;
    }
};

const Key = struct {
    string: []const u8,
    hash: u64,

    fn init(string: []const u8) Key {
        return .{
            .string = string,
            .key = std.hash.Wyhash.hash(413, string),
        };
    }
};

const KeyHashContext = struct {
    fn hash(_: KeyHashContext, key: Key) u64 {
        return key.hash;
    }
    fn eql(_: KeyHashContext, a: Key, b: Key) bool {
        return a.hash == b.hash and std.mem.eql(u8, a.string, b.string);
    }
};

// TODO: get rid of this
var global_random = @as(std.rand.DefaultPrng, undefined);
var init_global_random = std.once(struct {
    fn _init_global_random() void {
        global_random = std.rand.DefaultPrng.init(0);
    }
}._init_global_random);

fn key_random() Key {
    init_global_random.call();
    return global_random.random().int(Key);
}

fn calculate_standalone_sizes(first_sibling: *Block, font: rl.Font) void {
    var current_sibling: ?*Block = first_sibling;
    while (current_sibling) |block| : (current_sibling = block.next) {
        for (block.semantic_size) |semantic_size, i| {
            switch (semantic_size.kind) {
                .pixels => block.computed_size[i] = semantic_size.value,
                .text_content => {
                    block.computed_size[i] = if (block.string) |string| blk: {
                        const measurements = rl.MeasureTextEx(font, string, @intToFloat(f32, font.baseSize), 0);
                        break :blk switch (@intToEnum(Axis, i)) {
                            .x => measurements.x,
                            .y => measurements.y,
                        };
                    } else 0;
                },
                else => {},
            }
        }

        if (block.first) |first| calculate_standalone_sizes(first, font);
    }
}

fn calculate_upward_dependent_sizes(first_sibling: *Block) void {
    var current_sibling: ?*Block = first_sibling;
    while (current_sibling) |parent| : (current_sibling = parent.next) {
        var current_child = parent.first;
        while (current_child) |child| : (current_child = child.next) {
            for (child.semantic_size) |semantic_size, i| switch (semantic_size.kind) {
                .percent_of_parent => child.computed_size[i] = switch (parent.semantic_size[i].kind) {
                    .pixels, .text_content, .percent_of_parent => parent.computed_size[i] * semantic_size.value,
                    else => 0,
                },
                else => {},
            };
        }

        if (parent.first) |first| calculate_upward_dependent_sizes(first);
    }
}

fn calculate_downward_dependent_sizes(first_sibling: *Block) void {
    var current_sibling: ?*Block = first_sibling;
    while (current_sibling) |block| : (current_sibling = block.next) {
        if (block.first) |first| calculate_downward_dependent_sizes(first);

        for (block.semantic_size) |semantic_size, i| {
            switch (semantic_size.kind) {
                .children_sum => {
                    block.computed_size[i] = 0;

                    var current_child = block.first;
                    while (current_child) |child| : (current_child = child.next) {
                        if (@enumToInt(block.layout_axis) == i)
                            block.computed_size[i] += child.computed_size[i]
                        else
                            block.computed_size[i] = @max(block.computed_size[i], child.computed_size[i]);
                    }
                },
                else => {},
            }
        }
    }
}

fn solve_violations(first_parent: *Block) void {
    var current_parent: ?*Block = first_parent;
    while (current_parent) |block| : (current_parent = block.next) {
        for (block.semantic_size) |block_semantic_size, axis_idx| {
            _ = block_semantic_size;

            var children_size: f32 = 0;
            var minimum_children_size: f32 = 0;

            var current_child = block.first;
            while (current_child) |child| : (current_child = child.next) {
                if (@enumToInt(block.layout_axis) == axis_idx) {
                    children_size += child.computed_size[axis_idx];
                    minimum_children_size += child.computed_size[axis_idx] * child.semantic_size[axis_idx].strictness;
                } else {
                    children_size = @max(children_size, child.computed_size[axis_idx]);
                    minimum_children_size = @max(minimum_children_size, child.computed_size[axis_idx] * child.semantic_size[axis_idx].strictness);
                }
            }

            if (children_size > block.computed_size[axis_idx]) {
                current_child = block.first;
                var child_i: u32 = 0;
                while (current_child) |child| : (current_child = child.next) {
                    const strictness = child.semantic_size[axis_idx].strictness;
                    child_i += 1;
                    child.computed_size[axis_idx] *= strictness;
                    // const scale = (block.computed_size[axis_idx] - minimum_children_size) / (children_size - minimum_children_size);
                    const piece_of_the_pie = (block.computed_size[axis_idx] - minimum_children_size) * (1 - strictness);
                    if (piece_of_the_pie >= 0)
                        child.computed_size[axis_idx] += piece_of_the_pie;
                }
            }
        }

        if (block.first) |first| solve_violations(first);
    }
}

fn compute_relative_positions(block: *Block) void {
    if (!block.flags.positioned) {
        const parent_rect = if (block.parent) |parent| parent.rect else rl.Rectangle.init(0, 0, 0, 0);
        block.rect.x = parent_rect.x + block.computed_rel_position[0];
        block.rect.y = parent_rect.y + block.computed_rel_position[1];
    } else {
        block.rect.x = block.computed_rel_position[0];
        block.rect.y = block.computed_rel_position[1];
    }
    block.rect.width = block.computed_size[0];
    block.rect.height = block.computed_size[1];

    var current_position = [Axis.len]f32{ 0, 0 };
    var current_child = block.first;
    while (current_child) |child| : (current_child = child.next) {
        if (!child.flags.positioned) {
            child.computed_rel_position = current_position;
            current_position[@enumToInt(block.layout_axis)] += child.computed_size[@enumToInt(block.layout_axis)];
        }
    }

    if (block.first) |first| compute_relative_positions(first);
    if (block.next) |next| compute_relative_positions(next);
}

fn render_tree(ui: *Ui, block: *Block) void {
    std.debug.assert(block.rect.width >= 0);
    std.debug.assert(block.rect.height >= 0);

    ui.render_one_block(block);

    if (block.first) |first| ui.render_tree(first);
    if (block.next) |next| ui.render_tree(next);
}

fn render_one_block(ui: *Ui, block: *Block) void {
    const segments = 8;
    const radius = 4.0;
    const roundness = 2.0 * radius / @min(block.rect.width, block.rect.height);

    if (block.elevation > 0) {
        var shadow_rect = block.rect;
        shadow_rect.x += 4;
        shadow_rect.y += 4;
        const shadow_color = rl.Color.init(0, 0, 0, 0x60);

        if (block.flags.border) {
            rl.DrawRectangleRounded(shadow_rect, roundness, segments, shadow_color);
        } else {
            rl.DrawRectangleRec(shadow_rect, shadow_color);
        }
    }

    rl.BeginScissorModeRec(block.rect);

    const background_color = rl.Color.init(
        @truncate(u8, block.background_color >> 24),
        @truncate(u8, block.background_color >> 16),
        @truncate(u8, block.background_color >> 8),
        @truncate(u8, block.background_color),
    );
    if (block.flags.border) {
        rl.DrawRectangleRounded(block.rect, roundness, segments, background_color);
    } else {
        rl.DrawRectangleRec(block.rect, background_color);
    }

    if (block.string) |string| {
        const position = rl.Vector2.init(block.rect.x, block.rect.y);
        rl.DrawTextEx(ui.font, string, position, @intToFloat(f32, ui.font.baseSize), 0, rl.BLACK);
    }

    rl.EndScissorMode();

    if (block.flags.border) {
        const border_color = rl.Color.init(0xec, 0xec, 0xec, 0xff);
        const border_thickness = 2;
        rl.DrawRectangleRoundedLines(block.rect, roundness, segments, border_thickness, border_color);
    }
}
