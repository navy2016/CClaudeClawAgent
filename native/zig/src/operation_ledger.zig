const std = @import("std");
const types = @import("types.zig");

pub const Ledger = struct {
    allocator: std.mem.Allocator,
    committed: std.ArrayListUnmanaged(types.OperationBatch) = .{},
    undone: std.ArrayListUnmanaged(types.OperationBatch) = .{},

    pub fn init(allocator: std.mem.Allocator) Ledger {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *Ledger) void {
        for (self.committed.items) |*batch| batch.deinit(self.allocator);
        self.committed.deinit(self.allocator);
        for (self.undone.items) |*batch| batch.deinit(self.allocator);
        self.undone.deinit(self.allocator);
    }

    pub fn commit(self: *Ledger, batch: *types.OperationBatch) !void {
        batch.status = .committed;
        try self.committed.append(self.allocator, batch.*);
        batch.* = undefined;
        self.clearRedo();
    }

    pub fn undoLast(self: *Ledger) bool {
        if (self.committed.items.len == 0) return false;
        var batch = self.committed.pop();
        batch.status = .rolled_back;
        self.undone.append(self.allocator, batch) catch return false;
        return true;
    }

    pub fn redoLast(self: *Ledger) bool {
        if (self.undone.items.len == 0) return false;
        var batch = self.undone.pop();
        batch.status = .committed;
        self.committed.append(self.allocator, batch) catch return false;
        return true;
    }

    pub fn canUndo(self: Ledger) bool {
        return self.committed.items.len > 0;
    }

    pub fn canRedo(self: Ledger) bool {
        return self.undone.items.len > 0;
    }

    fn clearRedo(self: *Ledger) void {
        for (self.undone.items) |*batch| batch.deinit(self.allocator);
        self.undone.clearRetainingCapacity();
    }
};

test "ledger supports undo redo" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var ledger = Ledger.init(allocator);
    defer ledger.deinit();

    var batch = types.OperationBatch{
        .id = try allocator.dupe(u8, "b1"),
        .summary = try allocator.dupe(u8, "demo"),
    };
    try ledger.commit(&batch);
    try std.testing.expect(ledger.canUndo());
    try std.testing.expect(ledger.undoLast());
    try std.testing.expect(ledger.canRedo());
    try std.testing.expect(ledger.redoLast());
}
