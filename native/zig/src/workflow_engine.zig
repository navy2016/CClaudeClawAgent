const std = @import("std");
const types = @import("types.zig");

pub const WorkflowEngine = struct {
    allocator: std.mem.Allocator,
    run: ?types.WorkflowRun = null,

    pub fn init(allocator: std.mem.Allocator) WorkflowEngine {
        return .{ .allocator = allocator };
    }

    pub fn deinit(self: *WorkflowEngine) void {
        if (self.run) |*run| run.deinit(self.allocator);
    }

    pub fn start(self: *WorkflowEngine, workflow_type: types.WorkflowType) !void {
        if (self.run) |*run| run.deinit(self.allocator);
        var run = types.WorkflowRun{
            .run_id = try std.fmt.allocPrint(self.allocator, "run-{d}", .{std.time.milliTimestamp()}),
            .workflow_type = workflow_type,
            .state = .planning,
            .current_stage = .clarify,
        };

        const stages = switch (workflow_type) {
            .research => [_]types.StageKind{ .clarify, .discover, .gather_context, .hypothesis, .plan, .execute, .evaluate, .writeup, .summarize },
            .coding => [_]types.StageKind{ .clarify, .gather_context, .plan, .execute, .evaluate, .revise, .summarize },
            .analysis => [_]types.StageKind{ .clarify, .discover, .plan, .execute, .evaluate, .summarize },
            .general => [_]types.StageKind{ .clarify, .plan, .execute, .summarize },
        };
        for (stages) |stage| {
            try run.stages.append(self.allocator, .{ .kind = stage, .status = if (stage == .clarify) .doing else .todo });
        }
        self.run = run;
    }

    pub fn advance(self: *WorkflowEngine) void {
        if (self.run == null) return;
        var run = &self.run.?;
        var current_index: usize = 0;
        for (run.stages.items, 0..) |stage, idx| {
            if (stage.kind == run.current_stage) {
                current_index = idx;
                break;
            }
        }
        run.stages.items[current_index].status = .done;
        if (current_index + 1 < run.stages.items.len) {
            run.current_stage = run.stages.items[current_index + 1].kind;
            run.stages.items[current_index + 1].status = .doing;
            run.state = .running;
        } else {
            run.state = .completed;
        }
    }

    pub fn evaluate(self: *WorkflowEngine, score: f64, note: []const u8) !void {
        if (self.run == null) return;
        var run = &self.run.?;
        for (run.stages.items) |*stage| {
            if (stage.kind == .evaluate) {
                stage.status = if (score >= 0.75) .done else .failed;
                stage.score = score;
            }
        }
        if (score >= 0.75) {
            run.state = .running;
            run.current_stage = .summarize;
        } else {
            run.state = .revised;
            run.current_stage = .revise;
            try run.lessons.append(self.allocator, .{ .content = try self.allocator.dupe(u8, note) });
        }
    }
};

test "failed evaluation produces lesson and revise stage" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var engine = WorkflowEngine.init(allocator);
    defer engine.deinit();

    try engine.start(.coding);
    try engine.evaluate(0.4, "Tests failed, return to revise stage");
    try std.testing.expect(engine.run != null);
    try std.testing.expect(engine.run.?.current_stage == .revise);
    try std.testing.expect(engine.run.?.lessons.items.len == 1);
}
