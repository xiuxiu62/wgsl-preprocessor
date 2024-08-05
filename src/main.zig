const std = @import("std");

pub const ShaderError = error{
    CyclicDependency,
    ShaderNotFound,
};

pub const ShaderInfo = struct {
    name: []const u8,
    path: []const u8,
    dependencies: []const []const u8,
    code: []const u8,

    pub fn from(allocator: std.mem.Allocator, path: []const u8) !ShaderInfo {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const source_code = try file.readToEndAlloc(allocator, 16384);
        defer allocator.free(source_code);

        const name = std.fs.path.basename(path);

        return try ShaderInfo.parse(allocator, name, path, source_code);
    }

    pub fn parse(allocator: std.mem.Allocator, name: []const u8, path: []const u8, source_code: []const u8) !ShaderInfo {
        var dependencies = std.ArrayList([]const u8).init(allocator);
        errdefer dependencies.deinit();

        var code = std.ArrayList(u8).init(allocator);
        errdefer dependencies.deinit();

        std.debug.print("\n", .{});

        var line_iter = std.mem.split(u8, source_code, "\n");
        while (line_iter.next()) |line| {
            if (parse_module(line)) |module| {
                try dependencies.append(try allocator.dupe(u8, module));
            } else {
                try code.appendSlice(line);
                try code.append('\n');
            }
        }

        return .{
            .name = name,
            .path = path,
            .dependencies = try dependencies.toOwnedSlice(),
            .code = try code.toOwnedSlice(),
        };
    }

    fn parse_module(line: []const u8) ?[]const u8 {
        const import_prefix = "@import(\"";
        const import_sufix = ".wgsl\");";
        const trimmed_line = std.mem.trim(u8, line, &std.ascii.whitespace);

        if (std.mem.startsWith(u8, trimmed_line, import_prefix) and std.mem.endsWith(u8, trimmed_line, import_sufix)) {
            const result = trimmed_line[import_prefix.len .. trimmed_line.len - import_sufix.len];
            std.debug.print("Found module: {s}\n", .{result});

            return result;
        } else {
            std.debug.print("Found code: {s}\n", .{trimmed_line});
            return null;
        }
    }

    fn drop(self: *ShaderInfo, allocator: std.mem.Allocator) void {
        for (self.dependencies) |dep| allocator.free(dep);
        allocator.free(self.dependencies);
        allocator.free(self.code);
    }
};

pub const ShaderGraph = struct {
    allocator: std.mem.Allocator,
    nodes: std.StringHashMap(ShaderInfo),
    sorted_order: std.ArrayList([]const u8),

    pub fn new(allocator: std.mem.Allocator) ShaderGraph {
        return .{
            .allocator = allocator,
            .nodes = std.StringHashMap(ShaderInfo).init(allocator),
            .sorted_order = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn from_directory(
        allocator: std.mem.Allocator,
        dir_path: []const u8,
    ) !ShaderGraph {
        var graph = ShaderGraph.new(allocator);
        errdefer graph.drop();

        var dir = try std.fs.cwd().openDir(dir_path, .{ .iterate = true });
        defer dir.close();

        var walker = try dir.walk(allocator);
        defer walker.deinit();

        while (try walker.next()) |entry| {
            if (entry.kind == .file and std.mem.endsWith(u8, entry.path, ".wgsl")) {
                const full_path = try std.fs.path.join(allocator, &.{ dir_path, entry.path });
                defer allocator.free(full_path);

                const shader_info = try ShaderInfo.from(allocator, full_path);
                try graph.add_shader(shader_info);
            }
        }

        return graph;
    }

    // pub fn resolve_dependencies(self: *ShaderGraph) !void {}

    fn add_shader(self: *ShaderGraph, info: ShaderInfo) !void {
        try self.nodes.put(info.name, info);
    }

    // fn add_dependency(self: *ShaderGraph, name: []const u8, dependency: []const u8) !void {
    //     var node = self.nodes.getPtr(name) orelse return ShaderError.ShaderNotFound;
    //     try node.dependencies
    // }

    fn topological_sort(self: *ShaderGraph) !void {
        self.sorted_order.clearRetainingCapacity();
        var visited = std.AutoHashMap([]const u8, bool).init(self.allocator);
        defer visited.deinit();

        var stack = std.ArrayList([]const u8).init(self.allocator);
        defer stack.deinit();

        var it = self.nodes.keyIterator();
        while (it.next().?) |key| {
            if (!visited.contains(key.*)) {}
        }

        while (stack.popOrNull()) |shader| {
            try self.sorted_order.append(shader);
        }
    }

    fn visit(self: *ShaderGraph, shader_name: []const u8, visitied: std.AutoHashMap([]const u8, bool), stack: *std.ArrayList([]const u8)) !void {
        if (visitied.get(shader_name)) |v| {
            if (!v) return ShaderError.CyclicDependency;
            return;
        }

        try visitied.put(shader_name, false);

        if (self.nodes.get(shader_name)) |node|
            for (node.dependencies) |dep|
                try self.visit(dep, visitied, stack);

        try visitied.put(shader_name, true);
        try stack.append(shader_name);
    }

    fn get_combined_shader_code(self: *ShaderGraph) ![]const u8 {
        try self.topological_sort();

        var combined = std.ArrayList(u8).init(self.allocator);
        defer combined.deinit();

        for (self.sorted_order.items) |shader_name| {
            if (self.nodes.getPtr(shader_name)) |node| {
                try combined.appendSlice(node.code);
                try combined.append('\n');
            }
        }

        return combined.toOwnedSlice();
    }

    pub fn drop(self: *ShaderGraph) void {
        var it = self.nodes.valueIterator();
        while (it.next().?) |node| {
            node.deinit();
        }
        self.nodes.deinit();
        self.sorted_order.deinit();
    }
};

test "shader info parser works" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const name = "example";
    const path = "shaders/example.wgsl";
    const source_code =
        \\@import("common.wgsl"); 
        \\@import("lighting.wgsl"); 
        \\@import("camera.wgsl"); 
        \\
        \\@vertex fn vs_main() {}
        \\@fragment fn fs_main() {}
    ;

    const expected = struct {
        const dependencies: [3][]const u8 = .{ "common", "lighting", "camera" };
        const code =
            \\
            \\@vertex fn vs_main() {}
            \\@fragment fn fs_main() {}
        ;
    };

    var actual = try ShaderInfo.parse(allocator, name, path, source_code);
    defer actual.drop(allocator);

    try std.testing.expectEqualStrings(name, actual.name);
    try std.testing.expectEqualStrings(path, actual.path);

    try std.testing.expectEqual(expected.dependencies.len, actual.dependencies.len);
    for (expected.dependencies, actual.dependencies) |expected_dep, actual_dep|
        try std.testing.expectEqualStrings(expected_dep, actual_dep);

    var expected_line_iter = std.mem.split(u8, expected.code, "\n");
    var actual_line_iter = std.mem.split(u8, expected.code, "\n");

    while (expected_line_iter.next()) |expected_line| {
        const actual_line = actual_line_iter.next() orelse { // Check if actual has fewer lines than expected
            try std.testing.expect(false);
            break;
        };

        const expected_trimmed = std.mem.trim(u8, expected_line, &std.ascii.whitespace);
        const actual_trimmed = std.mem.trim(u8, actual_line, &std.ascii.whitespace);

        try std.testing.expectEqualStrings(expected_trimmed, actual_trimmed);
    }

    if (actual_line_iter.next() != null) // Check if actual has more lines than expected
        try std.testing.expect(false);
}
