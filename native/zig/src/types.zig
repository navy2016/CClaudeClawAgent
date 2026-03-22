const std = @import("std");

pub const RiskLevel = enum { safe, moderate, dangerous };
pub const ApprovalMode = enum { auto, cautious, strict, yolo };
pub const Reversibility = enum { reversible, compensating, irreversible };
pub const OperationType = enum {
    file_write,
    file_edit,
    file_delete,
    file_move,
    shell_exec,
    context_update,
    memory_append,
    workflow_transition,
};
pub const BatchStatus = enum {
    proposed,
    awaiting_approval,
    approved,
    rejected,
    committed,
    rolled_back,
};
pub const CommitStrategy = enum { all_or_nothing, staged_compensating };
pub const WorkflowType = enum { general, coding, research, analysis };
pub const WorkflowState = enum { idle, planning, running, evaluating, revised, completed, failed };
pub const StageKind = enum { clarify, gather_context, discover, hypothesis, plan, execute, evaluate, revise, summarize, writeup };
pub const StageStatus = enum { todo, doing, done, blocked, failed };

pub const Operation = struct {
    id: []u8,
    op_type: OperationType,
    target: []u8,
    args_json: []u8,
    dry_run_preview: []u8,
    risk: RiskLevel,
    reversibility: Reversibility,
    before_snapshot: ?[]u8 = null,
    after_snapshot: ?[]u8 = null,

    pub fn clone(self: Operation, allocator: std.mem.Allocator) !Operation {
        return .{
            .id = try allocator.dupe(u8, self.id),
            .op_type = self.op_type,
            .target = try allocator.dupe(u8, self.target),
            .args_json = try allocator.dupe(u8, self.args_json),
            .dry_run_preview = try allocator.dupe(u8, self.dry_run_preview),
            .risk = self.risk,
            .reversibility = self.reversibility,
            .before_snapshot = if (self.before_snapshot) |v| try allocator.dupe(u8, v) else null,
            .after_snapshot = if (self.after_snapshot) |v| try allocator.dupe(u8, v) else null,
        };
    }

    pub fn deinit(self: *Operation, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.target);
        allocator.free(self.args_json);
        allocator.free(self.dry_run_preview);
        if (self.before_snapshot) |v| allocator.free(v);
        if (self.after_snapshot) |v| allocator.free(v);
    }
};

pub const OperationBatch = struct {
    id: []u8,
    summary: []u8,
    operations: std.ArrayListUnmanaged(Operation) = .{},
    status: BatchStatus = .proposed,
    strategy: CommitStrategy = .all_or_nothing,
    reversible: bool = true,

    pub fn deinit(self: *OperationBatch, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.summary);
        for (self.operations.items) |*op| op.deinit(allocator);
        self.operations.deinit(allocator);
    }
};

pub const ApprovalDecision = enum { allow_once, allow_stage, deny };

pub const WorkflowStage = struct {
    kind: StageKind,
    status: StageStatus,
    score: ?f64 = null,
};

pub const Lesson = struct {
    content: []u8,
    decay_days: u16 = 30,

    pub fn deinit(self: *Lesson, allocator: std.mem.Allocator) void {
        allocator.free(self.content);
    }
};

pub const WorkflowRun = struct {
    run_id: []u8,
    workflow_type: WorkflowType,
    state: WorkflowState,
    current_stage: StageKind,
    stages: std.ArrayListUnmanaged(WorkflowStage) = .{},
    lessons: std.ArrayListUnmanaged(Lesson) = .{},

    pub fn deinit(self: *WorkflowRun, allocator: std.mem.Allocator) void {
        allocator.free(self.run_id);
        self.stages.deinit(allocator);
        for (self.lessons.items) |*lesson| lesson.deinit(allocator);
        self.lessons.deinit(allocator);
    }
};
