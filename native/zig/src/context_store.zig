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
    base_dir: []const u8,

    pub fn init(ally: std.mem.Allocator, base_dir: []const u8) !ContextStore {
        return .{
            .allocator = ally,
            .base_dir = try ally.dupe(u8, base_dir),
        };
    }

    pub fn deinit(self: *ContextStore) void {
        self.allocator.free(self.base_dir);
    }

    fn filePath(self: ContextStore, which: ContextFile) ![]u8 {
        return std.fs.path.join(self.allocator, &.{ self.base_dir, which.filename() });
    }

    pub fn ensureDefaults(self: ContextStore) !void {
        std.fs.cwd().makePath(self.base_dir) catch {};
        
        try self.ensureFile(.soul, 
            "# Soul\n\n" ++
            "**Name:** CClaudeClawAgent\n\n" ++
            "**Identity:** A focused coding assistant for Android/C projects\n\n" ++
            "## Goals\n" ++
            "- [P10] Help users efficiently complete programming tasks\n" ++
            "- [P8] Proactively discover potential issues in code\n" ++
            "- [P5] Teach design patterns when appropriate\n");
        
        try self.ensureFile(.user, "# User Profile\n\n");
        try self.ensureFile(.memory, "# Long-term Memory\n\n");
        try self.ensureFile(.lessons, "# Lessons\n\n");
        try self.ensureFile(.policy, "# Policy\n\n- approval_mode: cautious\n");
        try self.ensureFile(.bootstrap, "# Bootstrap\n\nIntroduce yourself and ask what should be optimized first.\n");
    }

    fn ensureFile(self: ContextStore, which: ContextFile, contents: []const u8) !void {
        const path = try self.filePath(which);
        defer self.allocator.free(path);
        
        if (std.fs.cwd().access(path, .{})) {
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
        
        const stat = try file.stat();
        if (stat.size > 1024 * 1024) return error.FileTooLarge;
        
        return try file.readToEndAlloc(self.allocator, @intCast(stat.size));
    }

    pub fn appendLine(self: ContextStore, which: ContextFile, line: []const u8) !void {
        const path = try self.filePath(which);
        defer self.allocator.free(path);
        
        var file = try std.fs.cwd().openFile(path, .{ .mode = .write_only });
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
            // Section not found, append it
            const new_section = try std.fmt.allocPrint(self.allocator, "\n## {s}\n{s}\n", .{section_title, new_body});
            defer self.allocator.free(new_section);
            
            const path = try self.filePath(which);
            defer self.allocator.free(path);
            var file = try std.fs.cwd().openFile(path, .{ .mode = .write_only });
            defer file.close();
            try file.seekFromEnd(0);
            try file.writeAll(new_section);
            return;
        };
        
        const after_header = old[start + header.len ..];
        const section_end = std.mem.indexOf(u8, after_header, "\n## ") orelse after_header.len;
        
        var new_content = std.ArrayList(u8).init(self.allocator);
        defer new_content.deinit();
        
        try new_content.appendSlice(old[0..start]);
        try new_content.appendSlice(header);
        try new_content.appendSlice("\n");
        try new_content.appendSlice(new_body);
        try new_content.appendSlice(after_header[section_end..]);

        const path = try self.filePath(which);
        defer self.allocator.free(path);
        var file = try std.fs.cwd().createFile(path, .{ .truncate = true });
        defer file.close();
        try file.writeAll(new_content.items);
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
