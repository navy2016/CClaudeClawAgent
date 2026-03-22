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
    id: []const u8,
    op_type: OperationType,
    target: []const u8,
    args_json: []const u8,
    dry_run_preview: []const u8,
    risk: RiskLevel,
    reversibility: Reversibility,
    before_snapshot: ?[]const u8 = null,
    after_snapshot: ?[]const u8 = null,
    
    pub fn clone(self: Operation, ally: std.mem.Allocator) !Operation {
        return .{
            .id = try ally.dupe(u8, self.id),
            .op_type = self.op_type,
            .target = try ally.dupe(u8, self.target),
            .args_json = try ally.dupe(u8, self.args_json),
            .dry_run_preview = try ally.dupe(u8, self.dry_run_preview),
            .risk = self.risk,
            .reversibility = self.reversibility,
            .before_snapshot = if (self.before_snapshot) |v| try ally.dupe(u8, v) else null,
            .after_snapshot = if (self.after_snapshot) |v| try ally.dupe(u8, v) else null,
        };
    }

    pub fn deinit(self: *Operation, ally: std.mem.Allocator) void {
        ally.free(self.id);
        ally.free(self.target);
        ally.free(self.args_json);
        ally.free(self.dry_run_preview);
        if (self.before_snapshot) |v| ally.free(v);
        if (self.after_snapshot) |v| ally.free(v);
    }
};

pub const OperationBatch = struct {
    id: []const u8,
    summary: []const u8,
    operations: std.ArrayList(Operation),
    status: BatchStatus = .proposed,
    strategy: CommitStrategy = .all_or_nothing,
    reversible: bool = true,

    pub fn init(ally: std.mem.Allocator, id: []const u8, summary: []const u8) !OperationBatch {
        return .{
            .id = try ally.dupe(u8, id),
            .summary = try ally.dupe(u8, summary),
            .operations = std.ArrayList(Operation).init(ally),
            .status = .proposed,
            .strategy = .all_or_nothing,
            .reversible = true,
        };
    }

    pub fn deinit(self: *OperationBatch, ally: std.mem.Allocator) void {
        ally.free(self.id);
        ally.free(self.summary);
        for (self.operations.items) |*op| op.deinit(ally);
        self.operations.deinit();
    }
};

pub const ApprovalDecision = enum { allow_once, allow_stage, deny };

pub const WorkflowStage = struct {
    kind: StageKind,
    status: StageStatus,
    score: ?f64 = null,
};

pub const Lesson = struct {
    content: []const u8,
    decay_days: u16 = 30,

    pub fn deinit(self: *Lesson, ally: std.mem.Allocator) void {
        ally.free(self.content);
    }
};

pub const WorkflowRun = struct {
    run_id: []const u8,
    workflow_type: WorkflowType,
    state: WorkflowState,
    current_stage: StageKind,
    stages: std.ArrayList(WorkflowStage),
    lessons: std.ArrayList(Lesson),

    pub fn init(ally: std.mem.Allocator, run_id: []const u8, wtype: WorkflowType) !WorkflowRun {
        return .{
            .run_id = try ally.dupe(u8, run_id),
            .workflow_type = wtype,
            .state = .planning,
            .current_stage = .clarify,
            .stages = std.ArrayList(WorkflowStage).init(ally),
            .lessons = std.ArrayList(Lesson).init(ally),
        };
    }

    pub fn deinit(self: *WorkflowRun, ally: std.mem.Allocator) void {
        ally.free(self.run_id);
        self.stages.deinit();
        for (self.lessons.items) |*lesson| lesson.deinit(ally);
        self.lessons.deinit();
    }
};
