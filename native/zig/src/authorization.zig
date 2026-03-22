const std = @import("std");
const types = @import("types.zig");

pub fn requiresApproval(mode: types.ApprovalMode, risk: types.RiskLevel) bool {
    return switch (mode) {
        .yolo => false,
        .auto => risk != .safe,
        .cautious => risk == .moderate or risk == .dangerous,
        .strict => true,
    };
}

pub fn analyzeBatch(batch: *types.OperationBatch) void {
    var reversible = true;
    for (batch.operations.items) |op| {
        if (op.reversibility == .irreversible) reversible = false;
        if (op.risk == .dangerous) {
            batch.strategy = .staged_compensating;
        }
    }
    batch.reversible = reversible;
}

pub fn batchMaxRisk(batch: *types.OperationBatch) types.RiskLevel {
    var current: types.RiskLevel = .safe;
    for (batch.operations.items) |op| {
        if (op.risk == .dangerous) return .dangerous;
        if (op.risk == .moderate) current = .moderate;
    }
    return current;
}
