const std = @import("std");
const types = @import("types.zig");

pub fn escape(writer: anytype, text: []const u8) !void {
    for (text) |c| {
        switch (c) {
            '"' => try writer.writeAll("\\\""),
            '\\' => try writer.writeAll("\\\\"),
            '\n' => try writer.writeAll("\\n"),
            '\r' => try writer.writeAll("\\r"),
            '\t' => try writer.writeAll("\\t"),
            else => try writer.writeByte(c),
        }
    }
}

pub fn writeQuoted(writer: anytype, text: []const u8) !void {
    try writer.writeByte('"');
    try escape(writer, text);
    try writer.writeByte('"');
}

pub fn enumTextRisk(r: types.RiskLevel) []const u8 {
    return switch (r) {
        .safe => "SAFE",
        .moderate => "MODERATE",
        .dangerous => "DANGEROUS",
    };
}

pub fn enumTextState(state: types.WorkflowState) []const u8 {
    return switch (state) {
        .idle => "idle",
        .planning => "planning",
        .running => "running",
        .evaluating => "evaluating",
        .revised => "revised",
        .completed => "completed",
        .failed => "failed",
    };
}

pub fn enumTextStage(stage: types.StageKind) []const u8 {
    return @tagName(stage);
}
