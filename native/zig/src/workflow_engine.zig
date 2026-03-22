const std = @import("std");
const types = @import("types.zig");

pub const WorkflowEngine = struct {
    allocator: std.mem.Allocator,
    run: ?types.WorkflowRun = null,

    pub fn init(ally: std.mem.Allocator) WorkflowEngine {
        return .{ .allocator = ally };
    }

    pub fn deinit(self: *WorkflowEngine) void {
        if (self.run) |*run| run.deinit(self.allocator);
    }

    pub fn start(self: *WorkflowEngine, workflow_type: types.WorkflowType) !void {
        if (self.run) |*run| run.deinit(self.allocator);
        
        const timestamp = std.time.milliTimestamp();
        const run_id = try std.fmt.allocPrint(self.allocator, "run-{d}", .{timestamp});
        
        var run = types.WorkflowRun{
            .run_id = run_id,
            .workflow_type = workflow_type,
            .state = .planning,
            .current_stage = .clarify,
            .stages = std.ArrayList(types.WorkflowStage).init(self.allocator),
            .lessons = std.ArrayList(types.Lesson).init(self.allocator),
        };

        const stages = switch (workflow_type) {
            .research => &[_]types.StageKind{ .clarify, .discover, .gather_context, .hypothesis, .plan, .execute, .evaluate, .writeup, .summarize },
            .coding => &[_]types.StageKind{ .clarify, .gather_context, .plan, .execute, .evaluate, .revise, .summarize },
            .analysis => &[_]types.StageKind{ .clarify, .discover, .plan, .execute, .evaluate, .summarize },
            .general => &[_]types.StageKind{ .clarify, .plan, .execute, .summarize },
        };
        
        for (stages) |stage| {
            try run.stages.append(.{ .kind = stage, .status = if (stage == .clarify) .doing else .todo });
        }
        self.run = run;
    }

    pub fn advance(self: *WorkflowEngine) void {
        if (self.run == null) return;
        var run = &self.run.?;
        
        // Find current stage index
        var current_idx: usize = 0;
        for (run.stages.items, 0..) |stage, idx| {
            if (stage.kind == run.current_stage) {
                current_idx = idx;
                break;
            }
        }
        
        // Mark current as done
        run.stages.items[current_idx].status = .done;
        
        // Move to next
        if (current_idx + 1 < run.stages.items.len) {
            run.current_stage = run.stages.items[current_idx + 1].kind;
            run.stages.items[current_idx + 1].status = .doing;
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
            const lesson_content = try self.allocator.dupe(u8, note);
            try run.lessons.append(.{ .content = lesson_content });
        }
    }
};
