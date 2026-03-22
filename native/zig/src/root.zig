const std = @import("std");
const types = @import("types.zig");
const session = @import("session.zig");
const context_store = @import("context_store.zig");

// Export FFI functions for JNI
const c = @cImport({
    @cInclude("stdint.h");
    @cInclude("stdlib.h");
});

// Global allocator for the library
var gpa: std.heap.GeneralPurposeAllocator(.{}) = .{};
var allocator: std.mem.Allocator = undefined;
var initialized = false;

fn ensureInitialized() void {
    if (!initialized) {
        allocator = gpa.allocator();
        initialized = true;
    }
}

// Helper to copy string to C memory
fn copyToC(ally: std.mem.Allocator, str: []const u8) [*:0]u8 {
    const mem = ally.alloc(u8, str.len + 1) catch @panic("OOM");
    @memcpy(mem.ptr, str);
    mem[str.len] = 0;
    return @ptrCast(mem.ptr);
}

// FFI Exports
export fn sessionCreate(data_dir: [*:0]const u8) i64 {
    ensureInitialized();
    const dir = std.mem.span(data_dir);
    const sess = session.Session.init(allocator, dir) catch return 0;
    return @intCast(@intFromPtr(sess));
}

export fn sessionDestroy(handle: i64) void {
    if (handle == 0) return;
    const sess: *session.Session = @ptrFromInt(@as(usize, @intCast(handle)));
    sess.deinit();
}

export fn sessionSendText(handle: i64, text: [*:0]const u8) [*:0]u8 {
    if (handle == 0) return copyToC(allocator, "{\"error\":\"invalid session\"}");
    const sess: *session.Session = @ptrFromInt(@as(usize, @intCast(handle)));
    const input = std.mem.span(text);
    const result = sess.sendText(input) catch |err| {
        const err_str = std.fmt.allocPrint(allocator, "{{\"error\":\"{s}\"}}", .{@errorName(err)}) catch return copyToC(allocator, "{\"error\":\"oom\"}");
        return copyToC(allocator, err_str);
    };
    return copyToC(allocator, result);
}

export fn sessionApproveBatch(handle: i64, batch_id: [*:0]const u8, scope: [*:0]const u8) [*:0]u8 {
    if (handle == 0) return copyToC(allocator, "{\"error\":\"invalid session\"}");
    const sess: *session.Session = @ptrFromInt(@as(usize, @intCast(handle)));
    const bid = std.mem.span(batch_id);
    const scp = std.mem.span(scope);
    const result = sess.approveBatch(bid, scp) catch |err| {
        const err_str = std.fmt.allocPrint(allocator, "{{\"error\":\"{s}\"}}", .{@errorName(err)}) catch return copyToC(allocator, "{\"error\":\"oom\"}");
        return copyToC(allocator, err_str);
    };
    return copyToC(allocator, result);
}

export fn sessionRejectBatch(handle: i64, batch_id: [*:0]const u8, reason: [*:0]const u8) [*:0]u8 {
    if (handle == 0) return copyToC(allocator, "{\"error\":\"invalid session\"}");
    const sess: *session.Session = @ptrFromInt(@as(usize, @intCast(handle)));
    const bid = std.mem.span(batch_id);
    const rsn = std.mem.span(reason);
    const result = sess.rejectBatch(bid, rsn) catch |err| {
        const err_str = std.fmt.allocPrint(allocator, "{{\"error\":\"{s}\"}}", .{@errorName(err)}) catch return copyToC(allocator, "{\"error\":\"oom\"}");
        return copyToC(allocator, err_str);
    };
    return copyToC(allocator, result);
}

export fn sessionUndo(handle: i64) [*:0]u8 {
    if (handle == 0) return copyToC(allocator, "{\"error\":\"invalid session\"}");
    const sess: *session.Session = @ptrFromInt(@as(usize, @intCast(handle)));
    const result = sess.undo() catch |err| {
        const err_str = std.fmt.allocPrint(allocator, "{{\"error\":\"{s}\"}}", .{@errorName(err)}) catch return copyToC(allocator, "{\"error\":\"oom\"}");
        return copyToC(allocator, err_str);
    };
    return copyToC(allocator, result);
}

export fn sessionRedo(handle: i64) [*:0]u8 {
    if (handle == 0) return copyToC(allocator, "{\"error\":\"invalid session\"}");
    const sess: *session.Session = @ptrFromInt(@as(usize, @intCast(handle)));
    const result = sess.redo() catch |err| {
        const err_str = std.fmt.allocPrint(allocator, "{{\"error\":\"{s}\"}}", .{@errorName(err)}) catch return copyToC(allocator, "{\"error\":\"oom\"}");
        return copyToC(allocator, err_str);
    };
    return copyToC(allocator, result);
}

// Memory free function for JNI
export fn cclaudeFree(ptr: ?[*]u8) void {
    if (ptr) |p| {
        allocator.free(p[0..1]); // This is a hack, proper length tracking needed
    }
}
