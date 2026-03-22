const std = @import("std");

pub const ContextFile = enum {
    soul,
    user,
    memory,
    lessons,
    policy,
    bootstrap,

    pub fn filename(self: ContextFile) []const u8 {
        return switch (self) {
            .soul => "SOUL.md",
            .user => "USER.md",
            .memory => "MEMORY.md",
            .lessons => "LESSONS.md",
            .policy => "POLICY.md",
            .bootstrap => "BOOTSTRAP.md",
        };
    }
};

pub const ContextStore = struct {
    allocator: std.mem.Allocator,
    base_dir: []u8,

    pub fn init(allocator: std.mem.Allocator, base_dir: []const u8) !ContextStore {
        const owned = try allocator.dupe(u8, base_dir);
        return .{ .allocator = allocator, .base_dir = owned };
    }

    pub fn deinit(self: *ContextStore) void {
        self.allocator.free(self.base_dir);
    }

    fn filePath(self: ContextStore, which: ContextFile) ![]u8 {
        return std.fs.path.join(self.allocator, &.{ self.base_dir, which.filename() });
    }

    pub fn ensureDefaults(self: ContextStore) !void {
        try std.fs.cwd().makePath(self.base_dir);
        try self.ensureFile(.soul, "# Soul\n\n**Name:** CClaudeClawAgent\n\n## Goals\n- [P10] Keep every action reversible whenever possible\n");
        try self.ensureFile(.user, "# User Profile\n\n");
        try self.ensureFile(.memory, "# Long-term Memory\n\n");
        try self.ensureFile(.lessons, "# Lessons\n\n");
        try self.ensureFile(.policy, "# Policy\n\n- approval_mode: cautious\n");
        try self.ensureFile(.bootstrap, "# Bootstrap\n\nIntroduce yourself and ask the user what should be optimized first.\n");
    }

    fn ensureFile(self: ContextStore, which: ContextFile, contents: []const u8) !void {
        const path = try self.filePath(which);
        defer self.allocator.free(path);
        if (std.fs.cwd().access(path, .{})) |_| {
            return;
        } else |_| {}
        var file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        try file.writeAll(contents);
    }

    pub fn read(self: ContextStore, which: ContextFile) ![]u8 {
        const path = try self.filePath(which);
        defer self.allocator.free(path);
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();
        return try file.readToEndAlloc(self.allocator, 1024 * 1024);
    }

    pub fn appendLine(self: ContextStore, which: ContextFile, line: []const u8) !void {
        const path = try self.filePath(which);
        defer self.allocator.free(path);
        var file = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
        defer file.close();
        try file.seekFromEnd(0);
        try file.writeAll(line);
        try file.writeAll("\n");
    }

    pub fn replaceSection(self: ContextStore, which: ContextFile, section_title: []const u8, new_body: []const u8) !void {
        const old = try self.read(which);
        defer self.allocator.free(old);

        const header = try std.fmt.allocPrint(self.allocator, "## {s}", .{section_title});
        defer self.allocator.free(header);

        const start = std.mem.indexOf(u8, old, header) orelse {
            const path = try self.filePath(which);
            defer self.allocator.free(path);
            var file = try std.fs.cwd().openFile(path, .{ .mode = .read_write });
            defer file.close();
            try file.seekFromEnd(0);
            try file.writeAll("
");
            try file.writeAll(header);
            try file.writeAll("
");
            try file.writeAll(new_body);
            try file.writeAll("
");
            return;
        };
        const after = old[start + header.len ..];
        const next_rel = std.mem.indexOf(u8, after, "\n## ") orelse after.len;

        var buf = std.ArrayList(u8).init(self.allocator);
        defer buf.deinit();
        try buf.appendSlice(old[0..start]);
        try buf.appendSlice(header);
        try buf.appendSlice("\n");
        try buf.appendSlice(new_body);
        try buf.appendSlice("\n");
        try buf.appendSlice(after[next_rel..]);

        const path = try self.filePath(which);
        defer self.allocator.free(path);
        var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
        defer file.close();
        try file.writeAll(buf.items);
    }

    pub fn buildPrompt(self: ContextStore) ![]u8 {
        const soul = try self.read(.soul);
        defer self.allocator.free(soul);
        const user = try self.read(.user);
        defer self.allocator.free(user);
        const memory = try self.read(.memory);
        defer self.allocator.free(memory);
        const lessons = try self.read(.lessons);
        defer self.allocator.free(lessons);

        return try std.fmt.allocPrint(
            self.allocator,
            "## Soul\n{s}\n## User\n{s}\n## Memory\n{s}\n## Lessons\n{s}\n",
            .{ soul, user, memory, lessons },
        );
    }
};

test "replaceSection keeps markdown structure" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const dir = "zig-out/test-context";
    var store = try ContextStore.init(allocator, dir);
    defer store.deinit();
    try store.ensureDefaults();
    try store.appendLine(.soul, "## Goals\n- [P8] Ask before dangerous actions");
    try store.replaceSection(.soul, "Goals", "- [P10] Never bypass authorization\n- [P9] Prefer reversible edits");
    const soul = try store.read(.soul);
    defer allocator.free(soul);
    try std.testing.expect(std.mem.indexOf(u8, soul, "Never bypass authorization") != null);
}
