const std = @import("std");
const platform = @import("../platform.zig");

const memory_pool = @import("memory_pool.zig");
const Block = @import("Block.zig");

//
//
// I'M DOOMED TO REPEAT Ui.zig
//
// I'M DOOMED TO REPEAT Ui.zig
//
// I'M DOOMED TO REPEAT Ui.zig
//
// I'M DOOMED TO REPEAT Ui.zig
//
//
const Cosmos = @This();
allocator: std.mem.Allocator,
block_pool: BlockPool,
blocks: std.AutoHashMapUnmanaged(usize, *Block) = .{},

const BlockPool = memory_pool.MemoryPool(Block);

pub fn init(allocator: std.mem.Allocator) Cosmos {
    return .{
        .allocator = allocator,
        .block_pool = BlockPool.initPreheated(allocator, 64),
    };
}

pub fn deinit(cosmos: *Cosmos) void {
    var i = cosmos.blocks.iterator();
    while (i.next()) |entry| {
        entry.value_ptr.*.deinit(cosmos.allocator);
    }
    cosmos.blocks.deinit(cosmos.iterator);
    cosmos.block_pool.deinit();
    cosmos.* = undefined;
}

pub fn paint(cosmos: *const Cosmos) void {
    _ = cosmos;
    // for (cosmos.blocks.items) |button| {
    //     button.paint();
    // }
}

pub fn put_button_at(cosmos: *Cosmos, left: f64, top: f64) void {
    const block = cosmos.blocks.addOne(cosmos.allocator) catch @panic("out of memory");
    block.* = Block{ .left = left, .top = top };
}

fn add_one(cosmos: *Cosmos) *Block {
    const block = cosmos.block_pool.create() catch @panic("out of memory");
    block.first = ;
    block.last = ;
    block.next = ;
    block.prev = ;
    block.parent = ;
}
