const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day05.txt");

pub fn main() !void {
    const part_one = try lowLoca(data);
    std.debug.print("part_one={d}\n", .{part_one});
    const part_tow = try lowLocaTow(data);
    std.debug.print("part_tow={d}\n", .{part_tow});
}

const CategoryMap = struct {
    destination: usize,
    source: usize,
    range: usize,
    kind: CategoryEnum,
};

const CategoryEnum = enum {
    soil,
    fertilizer,
    water,
    light,
    temperature,
    humidity,
    location,
};

fn lowLoca(doc: []const u8) !usize {
    var stream = std.io.fixedBufferStream(doc);
    var buf: [1024]u8 = undefined;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var hash_array = std.ArrayList(CategoryMap).init(arena.allocator());
    defer hash_array.deinit();
    var seeds: [1024]usize = undefined;
    var seed_index: usize = 0;
    var index: usize = 1;
    var min_loca: usize = std.math.maxInt(usize);
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            if (std.mem.eql(u8, line, "")) {
                continue;
            }
            if (std.mem.containsAtLeast(u8, line, 1, "map:")) {
                index += 1;
                continue;
            }
            switch (index) {
                1 => {
                    const seed = std.mem.trimLeft(u8, line, "seeds: ");
                    var it_seed = std.mem.splitSequence(u8, seed, " ");
                    while (it_seed.next()) |seed_str| {
                        seeds[seed_index] = try std.fmt.parseInt(usize, seed_str, 10);
                        seed_index += 1;
                    }
                },
                2 => {
                    var it_soil = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_soil.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_soil.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_soil.next().?, 10),
                        .kind = .soil,
                    });
                },
                3 => {
                    var it_fert = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_fert.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_fert.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_fert.next().?, 10),
                        .kind = .fertilizer,
                    });
                },
                4 => {
                    var it_water = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_water.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_water.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_water.next().?, 10),
                        .kind = .water,
                    });
                },
                5 => {
                    var it_light = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_light.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_light.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_light.next().?, 10),
                        .kind = .light,
                    });
                },
                6 => {
                    var it_temp = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_temp.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_temp.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_temp.next().?, 10),
                        .kind = .temperature,
                    });
                },
                7 => {
                    var it_humi = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_humi.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_humi.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_humi.next().?, 10),
                        .kind = .humidity,
                    });
                },
                8 => {
                    var it_loca = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_loca.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_loca.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_loca.next().?, 10),
                        .kind = .location,
                    });
                },
                else => {},
            }
        } else {
            break;
        }
    }
    for (0..seed_index) |i_seed| {
        var before: CategoryEnum = .soil;
        var curr: CategoryEnum = .soil;
        var is_map: bool = false;
        const seed = seeds[i_seed];
        var curr_num: usize = seed;
        for (hash_array.items) |item| {
            curr = item.kind;
            if (curr == before) {
                if ((curr_num >= item.source) and (curr_num <= item.source + item.range - 1) and (!is_map)) {
                    curr_num = item.destination + (curr_num - item.source);
                    is_map = true;
                }
            } else {
                is_map = false;
                if ((curr_num >= item.source) and (curr_num <= item.source + item.range - 1) and (!is_map)) {
                    curr_num = item.destination + (curr_num - item.source);
                    is_map = true;
                }
            }
            before = curr;
        }
        if (curr_num <= min_loca) {
            min_loca = curr_num;
        }
    }
    return min_loca;
}

fn lowLocaTow(doc: []const u8) !usize {
    var stream = std.io.fixedBufferStream(doc);
    var buf: [1024]u8 = undefined;
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var hash_array = std.ArrayList(CategoryMap).init(arena.allocator());
    defer hash_array.deinit();
    var seeds: [1024]usize = undefined;
    var seed_index: usize = 0;
    var index: usize = 1;
    var min_loca: usize = std.math.maxInt(usize);
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            if (std.mem.eql(u8, line, "")) {
                continue;
            }
            if (std.mem.containsAtLeast(u8, line, 1, "map:")) {
                index += 1;
                continue;
            }
            switch (index) {
                1 => {
                    const seed = std.mem.trimLeft(u8, line, "seeds: ");
                    var it_seed = std.mem.splitSequence(u8, seed, " ");
                    while (it_seed.next()) |seed_str| {
                        seeds[seed_index] = try std.fmt.parseInt(usize, seed_str, 10);
                        seed_index += 1;
                    }
                },
                2 => {
                    var it_soil = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_soil.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_soil.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_soil.next().?, 10),
                        .kind = .soil,
                    });
                },
                3 => {
                    var it_fert = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_fert.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_fert.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_fert.next().?, 10),
                        .kind = .fertilizer,
                    });
                },
                4 => {
                    var it_water = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_water.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_water.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_water.next().?, 10),
                        .kind = .water,
                    });
                },
                5 => {
                    var it_light = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_light.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_light.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_light.next().?, 10),
                        .kind = .light,
                    });
                },
                6 => {
                    var it_temp = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_temp.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_temp.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_temp.next().?, 10),
                        .kind = .temperature,
                    });
                },
                7 => {
                    var it_humi = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_humi.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_humi.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_humi.next().?, 10),
                        .kind = .humidity,
                    });
                },
                8 => {
                    var it_loca = std.mem.splitSequence(u8, line, " ");
                    try hash_array.append(.{
                        .destination = try std.fmt.parseInt(usize, it_loca.next().?, 10),
                        .source = try std.fmt.parseInt(usize, it_loca.next().?, 10),
                        .range = try std.fmt.parseInt(usize, it_loca.next().?, 10),
                        .kind = .location,
                    });
                },
                else => {},
            }
        } else {
            break;
        }
    }
    var start: usize = 0;
    for (0..seed_index) |i_seed| {
        if (i_seed % 2 == 0) {
            start = seeds[i_seed];
        } else {
            for (start..(start + seeds[i_seed])) |ir_seed| {
                var before: CategoryEnum = .soil;
                var curr: CategoryEnum = .soil;
                var is_map: bool = false;
                const seed = ir_seed;
                var curr_num: usize = seed;
                for (hash_array.items) |item| {
                    curr = item.kind;
                    if (curr == before) {
                        if ((curr_num >= item.source) and (curr_num <= item.source + item.range - 1) and (!is_map)) {
                            curr_num = item.destination + (curr_num - item.source);
                            is_map = true;
                        }
                    } else {
                        is_map = false;
                        if ((curr_num >= item.source) and (curr_num <= item.source + item.range - 1) and (!is_map)) {
                            curr_num = item.destination + (curr_num - item.source);
                            is_map = true;
                        }
                    }
                    before = curr;
                }
                if (curr_num <= min_loca) {
                    min_loca = curr_num;
                }
            }
        }
    }
    return min_loca;
}

test "part one example" {
    const doc =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;
    try std.testing.expect(try lowLoca(doc) == 35);
}

test "part two example" {
    const doc =
        \\seeds: 79 14 55 13
        \\
        \\seed-to-soil map:
        \\50 98 2
        \\52 50 48
        \\
        \\soil-to-fertilizer map:
        \\0 15 37
        \\37 52 2
        \\39 0 15
        \\
        \\fertilizer-to-water map:
        \\49 53 8
        \\0 11 42
        \\42 0 7
        \\57 7 4
        \\
        \\water-to-light map:
        \\88 18 7
        \\18 25 70
        \\
        \\light-to-temperature map:
        \\45 77 23
        \\81 45 19
        \\68 64 13
        \\
        \\temperature-to-humidity map:
        \\0 69 1
        \\1 0 69
        \\
        \\humidity-to-location map:
        \\60 56 37
        \\56 93 4
    ;
    try std.testing.expect(try lowLocaTow(doc) == 46);
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
