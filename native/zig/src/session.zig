const std = @import("std");
const types = @import("types.zig");
const context_mod = @import("context_store.zig");
const auth = @import("authorization.zig");
const ledger_mod = @import("operation_ledger.zig");
const workflow_mod = @import("workflow_engine.zig");
const jsonw = @import("json_writer.zig");

pub const Session = struct {
    allocator: std.mem.Allocator,
    approval_mode: types.ApprovalMode = .cautious,
    context_store: context_mod.ContextStore,
    ledger: ledger_mod.Ledger,
    workflow_engine: workflow_mod.WorkflowEngine,
    pending_batch: ?types.OperationBatch = null,

    pub fn init(allocator: std.mem.Allocator, data_dir: []const u8) !*Session {
        const self = try allocator.create(Session);
        const context_dir = try std.fs.path.join(allocator, &.{ data_dir, "context" });
        defer allocator.free(context_dir);
        self.* = .{
            .allocator = allocator,
            .context_store = try context_mod.ContextStore.init(allocator, context_dir),
            .ledger = ledger_mod.Ledger.init(allocator),
            .workflow_engine = workflow_mod.WorkflowEngine.init(allocator),
        };
        try self.context_store.ensureDefaults();
        return self;
    }

    pub fn deinit(self: *Session) void {
        if (self.pending_batch) |*batch| batch.deinit(self.allocator);
        self.workflow_engine.deinit();
        self.ledger.deinit();
        self.context_store.deinit();
        self.allocator.destroy(self);
    }

    pub fn sendText(self: *Session, text: []const u8) ![]u8 {
        const workflow_type = classifyWorkflow(text);
        if (self.workflow_engine.run == null) {
            try self.workflow_engine.start(workflow_type);
        }
        self.workflow_engine.advance();

        if (mentionsWriteLikeAction(text)) {
            var batch = try self.makeDemoBatch(text);
            auth.analyzeBatch(&batch);
            const max_risk = batchMaxRisk(&batch);
            batch.status = if (auth.requiresApproval(self.approval_mode, max_risk)) .awaiting_approval else .approved;
            if (batch.status == .approved) {
                try self.ledger.commit(&batch);
            } else {
                if (self.pending_batch) |*existing| existing.deinit(self.allocator);
                self.pending_batch = batch;
            }
        }

        return try self.snapshotJson(replyFor(text));
    }

    pub fn approveBatch(self: *Session, batch_id: []const u8, scope: []const u8) ![]u8 {
        _ = scope;
        if (self.pending_batch == null) return try self.snapshotJson("No pending batch.");
        var batch = self.pending_batch.?;
        self.pending_batch = null;
        if (!std.mem.eql(u8, batch.id, batch_id)) {
            self.pending_batch = batch;
            return try self.snapshotJson("Batch id mismatch.");
        }
        try self.ledger.commit(&batch);
        try self.workflow_engine.evaluate(0.86, "Committed approved batch successfully.");
        self.workflow_engine.advance();
        return try self.snapshotJson("Batch approved and committed.");
    }

    pub fn rejectBatch(self: *Session, batch_id: []const u8, reason: []const u8) ![]u8 {
        if (self.pending_batch) |*batch| {
            if (std.mem.eql(u8, batch.id, batch_id)) {
                batch.status = .rejected;
                try self.workflow_engine.evaluate(0.3, reason);
            }
        }
        if (self.pending_batch) |*batch| batch.deinit(self.allocator);
        self.pending_batch = null;
        return try self.snapshotJson("Batch rejected; workflow returned to revise/plan path.");
    }

    pub fn undo(self: *Session) ![]u8 {
        _ = self.ledger.undoLast();
        try self.workflow_engine.evaluate(0.4, "Undo triggered by user; return to revise stage.");
        return try self.snapshotJson("Last committed batch has been undone.");
    }

    pub fn redo(self: *Session) ![]u8 {
        _ = self.ledger.redoLast();
        try self.workflow_engine.evaluate(0.82, "Redo restored a previously rolled back batch.");
        return try self.snapshotJson("Last undone batch has been redone.");
    }

    fn classifyWorkflow(text: []const u8) types.WorkflowType {
        const lower = text;
        if (containsAny(lower, &.{ "research", "paper", "论文", "实验", "假设" })) return .research;
        if (containsAny(lower, &.{ "analyze", "analysis", "分析" })) return .analysis;
        if (containsAny(lower, &.{ "bug", "fix", "code", "refactor", "修复", "代码" })) return .coding;
        return .general;
    }

    fn mentionsWriteLikeAction(text: []const u8) bool {
        return containsAny(text, &.{ "write", "edit", "create", "修改", "写入", "创建" });
    }

    fn containsAny(text: []const u8, needles: []const []const u8) bool {
        for (needles) |needle| {
            if (std.ascii.indexOfIgnoreCase(text, needle) != null) return true;
        }
        return false;
    }

    fn replyFor(text: []const u8) []const u8 {
        if (containsAny(text, &.{ "research", "paper", "论文" })) {
            return "Switched into a research workflow with closed-loop evaluation, lessons, and rollback controls.";
        }
        if (mentionsWriteLikeAction(text)) {
            return "I converted the intended side effects into an atomic operation batch and prepared it for authorization.";
        }
        return "Goal captured. I am building a reversible plan before execution.";
    }

    fn makeDemoBatch(self: *Session, text: []const u8) !types.OperationBatch {
        var batch = types.OperationBatch{
            .id = try std.fmt.allocPrint(self.allocator, "batch-{d}", .{std.time.microTimestamp()}),
            .summary = try std.fmt.allocPrint(self.allocator, "Atomic batch for: {s}", .{text}),
        };
        try batch.operations.append(self.allocator, .{
            .id = try self.allocator.dupe(u8, "op-file-write"),
            .op_type = .file_write,
            .target = try self.allocator.dupe(u8, "/workspace/target.txt"),
            .args_json = try self.allocator.dupe(u8, "{\"path\":\"/workspace/target.txt\"}"),
            .dry_run_preview = try self.allocator.dupe(u8, "create or overwrite /workspace/target.txt"),
            .risk = .moderate,
            .reversibility = .reversible,
            .before_snapshot = try self.allocator.dupe(u8, ""),
            .after_snapshot = try self.allocator.dupe(u8, "new content"),
        });
        try batch.operations.append(self.allocator, .{
            .id = try self.allocator.dupe(u8, "op-workflow-transition"),
            .op_type = .workflow_transition,
            .target = try self.allocator.dupe(u8, @tagName(self.workflow_engine.run.?.current_stage)),
            .args_json = try self.allocator.dupe(u8, "{}"),
            .dry_run_preview = try self.allocator.dupe(u8, "advance workflow after approval"),
            .risk = .safe,
            .reversibility = .reversible,
            .before_snapshot = null,
            .after_snapshot = null,
        });
        return batch;
    }

    fn batchMaxRisk(batch: *types.OperationBatch) types.RiskLevel {
        var current: types.RiskLevel = .safe;
        for (batch.operations.items) |op| {
            if (op.risk == .dangerous) return .dangerous;
            if (op.risk == .moderate) current = .moderate;
        }
        return current;
    }

    pub fn snapshotJson(self: *Session, assistant_reply: []const u8) ![]u8 {
        var buf = std.ArrayList(u8).init(self.allocator);
        errdefer buf.deinit();
        const w = buf.writer();

        try w.writeByte('{');
        try w.writeAll("\"assistantReply\":");
        try jsonw.writeQuoted(w, assistant_reply);

        try w.writeAll(",\"pendingApproval\":");
        if (self.pending_batch) |*batch| {
            try self.writePendingApproval(w, batch);
        } else {
            try w.writeAll("null");
        }

        try w.writeAll(",\"workflow\":");
        if (self.workflow_engine.run) |*run| {
            try self.writeWorkflow(w, run);
        } else {
            try w.writeAll("null");
        }

        try std.fmt.format(w, ",\"canUndo\":{s},\"canRedo\":{s}", .{
            if (self.ledger.canUndo()) "true" else "false",
            if (self.ledger.canRedo()) "true" else "false",
        });
        try w.writeByte('}');
        return buf.toOwnedSlice();
    }

    fn writePendingApproval(self: *Session, writer: anytype, batch: *types.OperationBatch) !void {
        _ = self;
        try writer.writeByte('{');
        try writer.writeAll("\"batchId\":");
        try jsonw.writeQuoted(writer, batch.id);
        try writer.writeAll(",\"summary\":");
        try jsonw.writeQuoted(writer, batch.summary);
        try writer.writeAll(",\"riskLevel\":");
        try jsonw.writeQuoted(writer, jsonw.enumTextRisk(batchMaxRisk(batch)));
        try std.fmt.format(writer, ",\"reversible\":{s},\"operations\":[", .{if (batch.reversible) "true" else "false"});
        for (batch.operations.items, 0..) |op, idx| {
            if (idx != 0) try writer.writeByte(',');
            try writer.writeByte('{');
            try writer.writeAll("\"id\":");
            try jsonw.writeQuoted(writer, op.id);
            try writer.writeAll(",\"type\":");
            try jsonw.writeQuoted(writer, @tagName(op.op_type));
            try writer.writeAll(",\"target\":");
            try jsonw.writeQuoted(writer, op.target);
            try writer.writeAll(",\"preview\":");
            try jsonw.writeQuoted(writer, op.dry_run_preview);
            try writer.writeAll(",\"riskLevel\":");
            try jsonw.writeQuoted(writer, jsonw.enumTextRisk(op.risk));
            try std.fmt.format(writer, ",\"reversible\":{s}", .{if (op.reversibility != .irreversible) "true" else "false"});
            try writer.writeByte('}');
        }
        try writer.writeAll("]}");
    }

    fn writeWorkflow(self: *Session, writer: anytype, run: *types.WorkflowRun) !void {
        _ = self;
        try writer.writeByte('{');
        try writer.writeAll("\"runId\":");
        try jsonw.writeQuoted(writer, run.run_id);
        try writer.writeAll(",\"workflowType\":");
        try jsonw.writeQuoted(writer, @tagName(run.workflow_type));
        try writer.writeAll(",\"state\":");
        try jsonw.writeQuoted(writer, jsonw.enumTextState(run.state));
        try writer.writeAll(",\"currentStage\":");
        try jsonw.writeQuoted(writer, jsonw.enumTextStage(run.current_stage));
        try writer.writeAll(",\"stages\":[");
        for (run.stages.items, 0..) |stage, idx| {
            if (idx != 0) try writer.writeByte(',');
            try writer.writeByte('{');
            try writer.writeAll("\"kind\":");
            try jsonw.writeQuoted(writer, @tagName(stage.kind));
            try writer.writeAll(",\"status\":");
            try jsonw.writeQuoted(writer, @tagName(stage.status));
            if (stage.score) |score| {
                try std.fmt.format(writer, ",\"score\":{d}", .{score});
            }
            try writer.writeByte('}');
        }
        try writer.writeByte(']');
        try writer.writeAll(",\"latestLesson\":");
        if (run.lessons.items.len > 0) {
            try jsonw.writeQuoted(writer, run.lessons.items[run.lessons.items.len - 1].content);
        } else {
            try writer.writeAll("null");
        }
        try writer.writeByte('}');
    }
};
