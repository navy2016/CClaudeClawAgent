const std = @import("std");
const session_mod = @import("session.zig");

fn allocator() std.mem.Allocator {
    return std.heap.c_allocator;
}

fn ptrCastSession(handle: usize) *session_mod.Session {
    return @ptrFromInt(handle);
}

fn dupZ(bytes: []const u8) [*:0]u8 {
    const mem = allocator().alloc(u8, bytes.len + 1) catch unreachable;
    @memcpy(mem[0..bytes.len], bytes);
    mem[bytes.len] = 0;
    return @ptrCast(mem.ptr);
}

pub export fn sessionCreate(data_dir: [*:0]const u8) usize {
    const slice = std.mem.span(data_dir);
    const sess = session_mod.Session.init(allocator(), slice) catch return 0;
    return @intFromPtr(sess);
}

pub export fn sessionDestroy(handle: usize) void {
    if (handle == 0) return;
    const sess = ptrCastSession(handle);
    sess.deinit();
}

pub export fn sessionSendText(handle: usize, text: [*:0]const u8) [*:0]u8 {
    if (handle == 0) return dupZ("{\"assistantReply\":\"native session missing\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}");
    const sess = ptrCastSession(handle);
    const payload = sess.sendText(std.mem.span(text)) catch "{\"assistantReply\":\"sendText failed\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}";
    return dupZ(payload);
}

pub export fn sessionApproveBatch(handle: usize, batch_id: [*:0]const u8, scope: [*:0]const u8) [*:0]u8 {
    if (handle == 0) return dupZ("{\"assistantReply\":\"native session missing\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}");
    const sess = ptrCastSession(handle);
    const payload = sess.approveBatch(std.mem.span(batch_id), std.mem.span(scope)) catch "{\"assistantReply\":\"approve failed\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}";
    return dupZ(payload);
}

pub export fn sessionRejectBatch(handle: usize, batch_id: [*:0]const u8, reason: [*:0]const u8) [*:0]u8 {
    if (handle == 0) return dupZ("{\"assistantReply\":\"native session missing\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}");
    const sess = ptrCastSession(handle);
    const payload = sess.rejectBatch(std.mem.span(batch_id), std.mem.span(reason)) catch "{\"assistantReply\":\"reject failed\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}";
    return dupZ(payload);
}

pub export fn sessionUndo(handle: usize) [*:0]u8 {
    if (handle == 0) return dupZ("{\"assistantReply\":\"native session missing\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}");
    const sess = ptrCastSession(handle);
    const payload = sess.undo() catch "{\"assistantReply\":\"undo failed\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}";
    return dupZ(payload);
}

pub export fn sessionRedo(handle: usize) [*:0]u8 {
    if (handle == 0) return dupZ("{\"assistantReply\":\"native session missing\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}");
    const sess = ptrCastSession(handle);
    const payload = sess.redo() catch "{\"assistantReply\":\"redo failed\",\"pendingApproval\":null,\"workflow\":null,\"canUndo\":false,\"canRedo\":false}";
    return dupZ(payload);
}
