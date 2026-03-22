const std = @import("std");
const types = @import("types.zig");

pub const Ledger = struct {
    allocator: std.mem.Allocator,
    committed: std.ArrayList(types.OperationBatch),
    undone: std.ArrayList(types.OperationBatch),

    pub fn init(ally: std.mem.Allocator) Ledger {
        return .{
            .allocator = ally,
            .committed = std.ArrayList(types.OperationBatch).init(ally),
            .undone = std.ArrayList(types.OperationBatch).init(ally),
        };
    }

    pub fn deinit(self: *Ledger) void {
        for (self.committed.items) |*batch| batch.deinit(self.allocator);
        self.committed.deinit();
        for (self.undone.items) |*batch| batch.deinit(self.allocator);
        self.undone.deinit();
    }

    pub fn commit(self: *Ledger, batch: *types.OperationBatch) !void {
        batch.status = .committed;
        try self.committed.append(batch.*);
        self.clearRedo();
    }

    pub fn undoLast(self: *Ledger) bool {
        if (self.committed.items.len == 0) return false;
        var batch = self.committed.pop();
        batch.status = .rolled_back;
        self.undone.append(batch) catch return false;
        return true;
    }

    pub fn redoLast(self: *Ledger) bool {
        if (self.undone.items.len == 0) return false;
        var batch = self.undone.pop();
        batch.status = .committed;
        self.committed.append(batch) catch return false;
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
