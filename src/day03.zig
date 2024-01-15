const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day03.txt");

pub fn main() !void {
    const part_one = try getSumSchematic(data);
    std.debug.print("part_1, sum={d}\n", .{part_one});
    const part_tow = try getSumGearSchematic(data);
    std.debug.print("part_2, sum={d}\n", .{part_tow});
}

const Engine = struct {
    number: u8,
    hasSymbol: bool,
};

const Position = enum {
    first,
    middle,
    end,
};

const Asterisk = struct {
    x: usize,
    y: usize,
};

const Gear = struct {
    value: u32,
    asterisk: []Asterisk,
};

const GearRatio = struct {
    left: u32,
    right: u32,
    aster: Asterisk,
};

fn getSumSchematic(doc: []const u8) !usize {
    var stream = std.io.fixedBufferStream(doc);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var array = std.ArrayList([]u8).init(arena.allocator());
    defer array.deinit();
    var sum: usize = 0;

    var index: usize = 1;
    var pos: usize = 0;
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEofAlloc(arena.allocator(), '\n', 4096);
        if (line_maybe) |line| {
            try array.append(line);
            // first line
            if (pos == 1) {
                if (index == 2) {
                    try sumByLine(.first, &sum, array, &arena);
                }
            }
            // middle line
            if (pos == 2) {
                try sumByLine(.middle, &sum, array, &arena);
                pos = 0;
                _ = array.orderedRemove(0);
                pos += 1;
            }
            pos += 1;
            index += 1;
        } else {
            break;
        }
    }
    //process last element
    try sumByLine(.end, &sum, array, &arena);
    return sum;
}

fn getSumGearSchematic(doc: []const u8) !usize {
    var stream = std.io.fixedBufferStream(doc);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var array = std.ArrayList([]u8).init(arena.allocator());
    defer array.deinit();
    var gears = std.ArrayList(Gear).init(arena.allocator());
    defer gears.deinit();
    var asterisks = std.ArrayList(Asterisk).init(arena.allocator());
    defer asterisks.deinit();
    var sum: usize = 0;

    var index: usize = 1;
    var pos: usize = 0;
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEofAlloc(arena.allocator(), '\n', 4096);
        if (line_maybe) |line| {
            try array.append(line);
            // first line
            if (pos == 1) {
                if (index == 2) {
                    try sumGearRatio(.first, index, array, &gears, &arena, &asterisks);
                }
            }
            // middle line
            if (pos == 2) {
                try sumGearRatio(.middle, index, array, &gears, &arena, &asterisks);
                pos = 0;
                _ = array.orderedRemove(0);
                pos += 1;
            }
            pos += 1;
            index += 1;
        } else {
            break;
        }
    }
    //process last element
    try sumGearRatio(.end, index, array, &gears, &arena, &asterisks);
    try addAllSum(&gears, &sum, &arena, &asterisks);
    return sum;
}

fn isNum(c: u8) bool {
    const is_num = switch (c) {
        '0' => true,
        '1' => true,
        '2' => true,
        '3' => true,
        '4' => true,
        '5' => true,
        '6' => true,
        '7' => true,
        '8' => true,
        '9' => true,
        else => false,
    };
    return is_num;
}

fn isSymbol(c: u8) bool {
    const is_symbol = switch (c) {
        '0' => false,
        '1' => false,
        '2' => false,
        '3' => false,
        '4' => false,
        '5' => false,
        '6' => false,
        '7' => false,
        '8' => false,
        '9' => false,
        '.' => false,
        else => true,
    };
    return is_symbol;
}

fn isGear(c: u8) bool {
    const is_gear = switch (c) {
        '*' => true,
        else => false,
    };
    return is_gear;
}

fn gearChar(index: usize, i: usize, char: u8) ?Asterisk {
    if (isGear(char)) {
        return .{
            .x = i,
            .y = index,
        };
    } else {
        return null;
    }
}

fn gearPartNum(index: usize, i: usize, items: []u8, is_left: bool) ?Asterisk {
    if (is_left) {
        const left = @as(i32, @intCast(i)) - 1;
        if (left >= 0) {
            const left_u = @as(usize, @intCast(left));
            if (isGear(items[left_u])) {
                return .{
                    .x = left_u,
                    .y = index,
                };
            }
        }
    } else {
        const right = i + 1;
        if (right <= items.len - 1) {
            if (isGear(items[right])) {
                return .{
                    .x = right,
                    .y = index,
                };
            }
        }
    }
    return null;
}

fn isPartNum(i: usize, items: []u8, is_left: bool) bool {
    const is_part_num = false;
    if (is_left) {
        const left = @as(i32, @intCast(i)) - 1;
        if (left >= 0) {
            const left_u = @as(usize, @intCast(left));
            if (isSymbol(items[left_u])) {
                return true;
            }
        }
    } else {
        const right = i + 1;
        if (right <= items.len - 1) {
            if (isSymbol(items[right])) {
                return true;
            }
        }
    }
    return is_part_num;
}

fn sumByLine(p: Position, sum: *usize, array: std.ArrayList([]u8), arena: *std.heap.ArenaAllocator) !void {
    switch (p) {
        .first => blk: {
            var buf: [100]Engine = undefined;
            var buf_i: usize = 0;
            for (array.items[0], 0.., array.items[1], 0..) |char, char_i, dc, dc_i| {
                if (isNum(char)) {
                    buf[buf_i] = .{
                        .number = char,
                        .hasSymbol = false,
                    };
                    if (isSymbol(dc) or
                        (isPartNum(char_i, array.items[0], false)) or
                        (isPartNum(dc_i, array.items[1], false)) or
                        (isPartNum(dc_i, array.items[1], true)) or
                        (isPartNum(char_i, array.items[0], true)))
                    {
                        buf[buf_i].hasSymbol = true;
                    }
                    buf_i += 1;
                    if (char_i == array.items[1].len - 1) {
                        if (buf_i > 0) {
                            var value = std.ArrayList(u8).init(arena.allocator());
                            defer value.deinit();
                            var isNumValue: bool = false;
                            for (0..buf_i) |i| {
                                try value.append(buf[i].number);
                                if (buf[i].hasSymbol == true) {
                                    //label this number is part number
                                    isNumValue = true;
                                }
                            }
                            if (isNumValue) {
                                const part_num = try parseInt(u32, value.items, 10);
                                sum.* += part_num;
                            }
                        }
                    }
                } else {
                    if (buf_i > 0) {
                        var value = std.ArrayList(u8).init(arena.allocator());
                        defer value.deinit();
                        var isNumValue: bool = false;
                        for (0..buf_i) |i| {
                            try value.append(buf[i].number);
                            if (buf[i].hasSymbol == true) {
                                //label this number is part number
                                isNumValue = true;
                            }
                        }
                        if (isNumValue) {
                            const part_num = try parseInt(u32, value.items, 10);
                            sum.* += part_num;
                        }
                    }
                    buf_i = 0;
                }
            }
            break :blk;
        },
        .middle => blk: {
            var buf: [100]Engine = undefined;
            var buf_i: usize = 0;
            for (array.items[1], 0.., array.items[2], 0.., array.items[0], 0..) |char, char_i, dc, dc_i, uc, uc_i| {
                if (isNum(char)) {
                    buf[buf_i] = .{
                        .number = char,
                        .hasSymbol = false,
                    };
                    if (isSymbol(dc) or isSymbol(uc) or
                        (isPartNum(char_i, array.items[1], false)) or
                        (isPartNum(dc_i, array.items[2], false)) or
                        (isPartNum(dc_i, array.items[2], true)) or
                        (isPartNum(uc_i, array.items[0], false)) or
                        (isPartNum(uc_i, array.items[0], true)) or
                        (isPartNum(char_i, array.items[1], true)))
                    {
                        buf[buf_i].hasSymbol = true;
                    }
                    buf_i += 1;
                    if (char_i == array.items[1].len - 1) {
                        if (buf_i > 0) {
                            var value = std.ArrayList(u8).init(arena.allocator());
                            defer value.deinit();
                            var isNumValue: bool = false;
                            for (0..buf_i) |i| {
                                try value.append(buf[i].number);
                                if (buf[i].hasSymbol == true) {
                                    //label this number is part number
                                    isNumValue = true;
                                }
                            }
                            if (isNumValue) {
                                const part_num = try parseInt(u32, value.items, 10);
                                sum.* += part_num;
                            }
                        }
                    }
                } else {
                    if (buf_i > 0) {
                        var value = std.ArrayList(u8).init(arena.allocator());
                        defer value.deinit();
                        var isNumValue: bool = false;
                        for (0..buf_i) |i| {
                            try value.append(buf[i].number);
                            if (buf[i].hasSymbol == true) {
                                //label this number is part number
                                isNumValue = true;
                            }
                        }
                        if (isNumValue) {
                            const part_num = try parseInt(u32, value.items, 10);
                            sum.* += part_num;
                        }
                    }
                    buf_i = 0;
                }
            }
            break :blk;
        },
        .end => blk: {
            var buf: [100]Engine = undefined;
            var buf_i: usize = 0;
            for (array.items[1], 0.., array.items[0], 0..) |char, char_i, uc, uc_i| {
                if (isNum(char)) {
                    buf[buf_i] = .{
                        .number = char,
                        .hasSymbol = false,
                    };
                    if (isSymbol(uc) or
                        (isPartNum(char_i, array.items[1], false)) or
                        (isPartNum(uc_i, array.items[0], false)) or
                        (isPartNum(uc_i, array.items[0], true)) or
                        (isPartNum(char_i, array.items[1], true)))
                    {
                        buf[buf_i].hasSymbol = true;
                    }
                    buf_i += 1;
                    if (char_i == array.items[1].len - 1) {
                        if (buf_i > 0) {
                            var value = std.ArrayList(u8).init(arena.allocator());
                            defer value.deinit();
                            var isNumValue: bool = false;
                            for (0..buf_i) |i| {
                                try value.append(buf[i].number);
                                if (buf[i].hasSymbol == true) {
                                    //label this number is part number
                                    isNumValue = true;
                                }
                            }
                            if (isNumValue) {
                                const part_num = try parseInt(u32, value.items, 10);
                                sum.* += part_num;
                            }
                        }
                    }
                } else {
                    if (buf_i > 0) {
                        var value = std.ArrayList(u8).init(arena.allocator());
                        defer value.deinit();
                        var isNumValue: bool = false;
                        for (0..buf_i) |i| {
                            try value.append(buf[i].number);
                            if (buf[i].hasSymbol == true) {
                                //label this number is part number
                                isNumValue = true;
                            }
                        }
                        if (isNumValue) {
                            const part_num = try parseInt(u32, value.items, 10);
                            sum.* += part_num;
                        }
                    }
                    buf_i = 0;
                }
            }
            break :blk;
        },
    }
}

fn addAllSum(gears: *std.ArrayList(Gear), sum: *usize, arena: *std.heap.ArenaAllocator, asterisks: *std.ArrayList(Asterisk)) !void {
    var map_aster = std.AutoHashMap(Asterisk, void).init(arena.allocator());
    defer map_aster.deinit();
    for (asterisks.items) |aster| {
        try map_aster.put(aster, {});
    }
    var buf: [2]u32 = undefined;
    var flag: [2]bool = [_]bool{ false, false };
    var it = map_aster.keyIterator();
    while (it.next()) |key| {
        var adjacent: usize = 0;
        for (gears.items) |cur| {
            for (cur.asterisk) |aster| {
                if ((key.*.x == aster.x) and (key.*.y == aster.y)) {
                    adjacent += 1;
                    break;
                }
            }
            if ((adjacent == 1) and (!flag[0])) {
                buf[0] = cur.value;
                flag[0] = true;
            }
            if ((adjacent == 2) and (!flag[1])) {
                buf[1] = cur.value;
                flag[1] = true;
            }
        }
        if (adjacent == 2) {
            //calculate
            sum.* += buf[0] * buf[1];
        }
        flag[0] = false;
        flag[1] = false;
    }
}

fn sumGearRatio(p: Position, index: usize, array: std.ArrayList([]u8), gears: *std.ArrayList(Gear), arena: *std.heap.ArenaAllocator, asterisks: *std.ArrayList(Asterisk)) !void {
    var old_len = asterisks.items.len;
    switch (p) {
        .first => blk: {
            var buf: [100]Engine = undefined;
            var buf_i: usize = 0;
            for (array.items[0], 0.., array.items[1], 0..) |char, char_i, dc, dc_i| {
                if (isNum(char)) {
                    buf[buf_i] = .{
                        .number = char,
                        .hasSymbol = false,
                    };
                    if (isSymbol(dc) or
                        (isPartNum(char_i, array.items[0], false)) or
                        (isPartNum(dc_i, array.items[1], false)) or
                        (isPartNum(dc_i, array.items[1], true)) or
                        (isPartNum(char_i, array.items[0], true)))
                    {
                        buf[buf_i].hasSymbol = true;
                    }
                    if (gearChar(index, dc_i, dc) != null) {
                        try asterisks.append(gearChar(index, dc_i, dc).?);
                    }

                    if (gearPartNum(index - 1, char_i, array.items[0], false) != null) {
                        try asterisks.append(gearPartNum(index - 1, char_i, array.items[0], false).?);
                    }

                    if (gearPartNum(index, dc_i, array.items[1], false) != null) {
                        try asterisks.append(gearPartNum(index, dc_i, array.items[1], false).?);
                    }

                    if (gearPartNum(index, dc_i, array.items[1], true) != null) {
                        try asterisks.append(gearPartNum(index, dc_i, array.items[1], true).?);
                    }

                    if (gearPartNum(index - 1, char_i, array.items[0], true) != null) {
                        try asterisks.append(gearPartNum(index - 1, char_i, array.items[0], true).?);
                    }

                    buf_i += 1;
                    if (char_i == array.items[1].len - 1) {
                        if (buf_i > 0) {
                            var value = std.ArrayList(u8).init(arena.allocator());
                            defer value.deinit();
                            var isNumValue: bool = false;
                            for (0..buf_i) |i| {
                                try value.append(buf[i].number);
                                if (buf[i].hasSymbol == true) {
                                    //label this number is part number
                                    isNumValue = true;
                                }
                            }
                            if (isNumValue) {
                                const part_num = try parseInt(u32, value.items, 10);
                                if (asterisks.items.len > old_len) {
                                    try gears.append(.{
                                        .value = part_num,
                                        .asterisk = try arena.allocator().dupe(Asterisk, asterisks.items[old_len..]),
                                    });
                                }
                            }
                        }
                    }
                } else {
                    if (buf_i > 0) {
                        var value = std.ArrayList(u8).init(arena.allocator());
                        defer value.deinit();
                        var isNumValue: bool = false;
                        for (0..buf_i) |i| {
                            try value.append(buf[i].number);
                            if (buf[i].hasSymbol == true) {
                                //label this number is part number
                                isNumValue = true;
                            }
                        }
                        if (isNumValue) {
                            const part_num = try parseInt(u32, value.items, 10);
                            if (asterisks.items.len > old_len) {
                                try gears.append(.{
                                    .value = part_num,
                                    .asterisk = try arena.allocator().dupe(Asterisk, asterisks.items[old_len..]),
                                });
                                old_len = asterisks.items.len;
                            }
                        }
                    }
                    buf_i = 0;
                }
            }
            break :blk;
        },
        .middle => blk: {
            var buf: [100]Engine = undefined;
            var buf_i: usize = 0;
            for (array.items[1], 0.., array.items[2], 0.., array.items[0], 0..) |char, char_i, dc, dc_i, uc, uc_i| {
                if (isNum(char)) {
                    buf[buf_i] = .{
                        .number = char,
                        .hasSymbol = false,
                    };
                    if (isSymbol(dc) or isSymbol(uc) or
                        (isPartNum(char_i, array.items[1], false)) or
                        (isPartNum(dc_i, array.items[2], false)) or
                        (isPartNum(dc_i, array.items[2], true)) or
                        (isPartNum(uc_i, array.items[0], false)) or
                        (isPartNum(uc_i, array.items[0], true)) or
                        (isPartNum(char_i, array.items[1], true)))
                    {
                        buf[buf_i].hasSymbol = true;
                    }
                    if (gearChar(index, dc_i, dc) != null) {
                        try asterisks.append(gearChar(index, dc_i, dc).?);
                    }
                    if (gearChar(index - 2, uc_i, uc) != null) {
                        try asterisks.append(gearChar(index - 2, uc_i, uc).?);
                    }

                    if (gearPartNum(index - 1, char_i, array.items[1], false) != null) {
                        try asterisks.append(gearPartNum(index - 1, char_i, array.items[1], false).?);
                    }

                    if (gearPartNum(index, dc_i, array.items[2], false) != null) {
                        try asterisks.append(gearPartNum(index, dc_i, array.items[2], false).?);
                    }

                    if (gearPartNum(index, dc_i, array.items[2], true) != null) {
                        try asterisks.append(gearPartNum(index, dc_i, array.items[2], true).?);
                    }

                    if (gearPartNum(index - 2, uc_i, array.items[0], false) != null) {
                        try asterisks.append(gearPartNum(index - 2, uc_i, array.items[0], false).?);
                    }

                    if (gearPartNum(index - 2, uc_i, array.items[0], true) != null) {
                        try asterisks.append(gearPartNum(index - 2, uc_i, array.items[0], true).?);
                    }

                    if (gearPartNum(index - 1, char_i, array.items[1], true) != null) {
                        try asterisks.append(gearPartNum(index - 1, char_i, array.items[1], true).?);
                    }

                    buf_i += 1;
                    if (char_i == array.items[1].len - 1) {
                        if (buf_i > 0) {
                            var value = std.ArrayList(u8).init(arena.allocator());
                            defer value.deinit();
                            var isNumValue: bool = false;
                            for (0..buf_i) |i| {
                                try value.append(buf[i].number);
                                if (buf[i].hasSymbol == true) {
                                    //label this number is part number
                                    isNumValue = true;
                                }
                            }
                            if (isNumValue) {
                                const part_num = try parseInt(u32, value.items, 10);
                                if (asterisks.items.len > old_len) {
                                    try gears.append(.{
                                        .value = part_num,
                                        .asterisk = try arena.allocator().dupe(Asterisk, asterisks.items[old_len..]),
                                    });
                                }
                            }
                        }
                    }
                } else {
                    if (buf_i > 0) {
                        var value = std.ArrayList(u8).init(arena.allocator());
                        defer value.deinit();
                        var isNumValue: bool = false;
                        for (0..buf_i) |i| {
                            try value.append(buf[i].number);
                            if (buf[i].hasSymbol == true) {
                                //label this number is part number
                                isNumValue = true;
                            }
                        }
                        if (isNumValue) {
                            const part_num = try parseInt(u32, value.items, 10);
                            if (asterisks.items.len > old_len) {
                                try gears.append(.{
                                    .value = part_num,
                                    .asterisk = try arena.allocator().dupe(Asterisk, asterisks.items[old_len..]),
                                });
                                old_len = asterisks.items.len;
                            }
                        }
                    }
                    buf_i = 0;
                }
            }
            break :blk;
        },
        .end => blk: {
            var buf: [100]Engine = undefined;
            var buf_i: usize = 0;
            for (array.items[1], 0.., array.items[0], 0..) |char, char_i, uc, uc_i| {
                if (isNum(char)) {
                    buf[buf_i] = .{
                        .number = char,
                        .hasSymbol = false,
                    };
                    if (isSymbol(uc) or
                        (isPartNum(char_i, array.items[1], false)) or
                        (isPartNum(uc_i, array.items[0], false)) or
                        (isPartNum(uc_i, array.items[0], true)) or
                        (isPartNum(char_i, array.items[1], true)))
                    {
                        buf[buf_i].hasSymbol = true;
                    }
                    if (gearChar(index - 2, uc_i, uc) != null) {
                        try asterisks.append(gearChar(index - 2, uc_i, uc).?);
                    }

                    if (gearPartNum(index - 1, char_i, array.items[1], false) != null) {
                        try asterisks.append(gearPartNum(index - 1, char_i, array.items[1], false).?);
                    }

                    if (gearPartNum(index - 2, uc_i, array.items[0], false) != null) {
                        try asterisks.append(gearPartNum(index - 2, uc_i, array.items[0], false).?);
                    }

                    if (gearPartNum(index - 2, uc_i, array.items[0], true) != null) {
                        try asterisks.append(gearPartNum(index - 2, uc_i, array.items[0], true).?);
                    }

                    if (gearPartNum(index - 1, char_i, array.items[1], true) != null) {
                        try asterisks.append(gearPartNum(index - 1, char_i, array.items[1], true).?);
                    }
                    buf_i += 1;
                    if (char_i == array.items[1].len - 1) {
                        if (buf_i > 0) {
                            var value = std.ArrayList(u8).init(arena.allocator());
                            defer value.deinit();
                            var isNumValue: bool = false;
                            for (0..buf_i) |i| {
                                try value.append(buf[i].number);
                                if (buf[i].hasSymbol == true) {
                                    //label this number is part number
                                    isNumValue = true;
                                }
                            }
                            if (isNumValue) {
                                const part_num = try parseInt(u32, value.items, 10);
                                if (asterisks.items.len > old_len) {
                                    try gears.append(.{
                                        .value = part_num,
                                        .asterisk = try arena.allocator().dupe(Asterisk, asterisks.items[old_len..]),
                                    });
                                }
                            }
                        }
                    }
                } else {
                    if (buf_i > 0) {
                        var value = std.ArrayList(u8).init(arena.allocator());
                        defer value.deinit();
                        var isNumValue: bool = false;
                        for (0..buf_i) |i| {
                            try value.append(buf[i].number);
                            if (buf[i].hasSymbol == true) {
                                //label this number is part number
                                isNumValue = true;
                            }
                        }
                        if (isNumValue) {
                            const part_num = try parseInt(u32, value.items, 10);
                            if (asterisks.items.len > old_len) {
                                try gears.append(.{
                                    .value = part_num,
                                    .asterisk = try arena.allocator().dupe(Asterisk, asterisks.items[old_len..]),
                                });
                                old_len = asterisks.items.len;
                            }
                        }
                    }
                    buf_i = 0;
                }
            }
            break :blk;
        },
    }
}

test "part 1 example" {
    const doc =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    try std.testing.expect(try getSumSchematic(doc) == 4361);
}

test "part 2 example" {
    const doc =
        \\467..114..
        \\...*......
        \\..35..633.
        \\......#...
        \\617*......
        \\.....+.58.
        \\..592.....
        \\......755.
        \\...$.*....
        \\.664.598..
    ;
    try std.testing.expect(try getSumGearSchematic(doc) == 467835);
}
// Useful stdlib functions
const tokenizeAny = std.mem.tokenizeAny;
const tokenizeSeq = std.mem.tokenizeSequence;
const tokenizeSca = std.mem.tokenizeScalar;
const splitAny = std.mem.splitAny;
const splitSeq = std.mem.splitSequence;
const splitSca = std.mem.splitScalar;
const indexOf = std.mem.indexOfScalar;
const indexOfAny = std.mem.indexOfAny;
const indexOfStr = std.mem.indexOfPosLinear;
const lastIndexOf = std.mem.lastIndexOfScalar;
const lastIndexOfAny = std.mem.lastIndexOfAny;
const lastIndexOfStr = std.mem.lastIndexOfLinear;
const trim = std.mem.trim;
const sliceMin = std.mem.min;
const sliceMax = std.mem.max;

const parseInt = std.fmt.parseInt;
const parseFloat = std.fmt.parseFloat;

const print = std.debug.print;
const assert = std.debug.assert;

const sort = std.sort.block;
const asc = std.sort.asc;
const desc = std.sort.desc;

// Generated from template/template.zig.
// Run `zig build generate` to update.
// Only unmodified days will be updated.
