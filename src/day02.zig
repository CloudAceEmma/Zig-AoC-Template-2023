const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day02.txt");

pub fn main() !void {
    const part1_sum = try getGameIdSum(data);
    std.debug.print("part1, sum={d}\n", .{part1_sum});
    const part2_sum = try getMxGameIdSum(data);
    std.debug.print("part2, sum={d}\n", .{part2_sum});
}

const CubeMap = struct {
    size: usize,
    cube: []const u8,
};

const CubeSet = struct {
    cubeB: CubeMap,
    cubeR: CubeMap,
    cubeG: CubeMap,
};

fn getGameIdSum(doc: []const u8) !usize {
    var sum: usize = 0;
    var buf: [1024]u8 = undefined;
    var stream = std.io.fixedBufferStream(doc);
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            // split Game and cubes
            var it = splitSeq(u8, line, ": ");
            var game_heade = splitSeq(u8, it.first(), " ");
            _ = game_heade.first();
            var id = try parseInt(usize, game_heade.rest(), 10);
            var it_set = splitSeq(u8, it.rest(), "; ");
            const flag_f = try splitCube(it_set.first());
            if (flag_f) {
                while (true) {
                    if (it_set.next()) |set| {
                        //std.debug.print("{s}\n", .{set});
                        //split cube
                        const flag_r = try splitCube(set);
                        if (!flag_r) {
                            id = 0;
                        }
                    } else {
                        break;
                    }
                }
            } else {
                id = 0;
            }
            sum += id;
        } else {
            break;
        }
    }
    return sum;
}

fn getMxGameIdSum(doc: []const u8) !usize {
    var sum: usize = 0;
    var buf: [1024]u8 = undefined;
    var stream = std.io.fixedBufferStream(doc);
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            var cube_set_mx: CubeSet = .{
                .cubeB = .{ .size = 0, .cube = "blue" },
                .cubeR = .{ .size = 0, .cube = "red" },
                .cubeG = .{ .size = 0, .cube = "green" },
            };
            // split Game and cubes
            var it = splitSeq(u8, line, ": ");
            _ = it.first();
            var it_set = splitSeq(u8, it.rest(), "; ");
            try splitMaxCube(it_set.first(), &cube_set_mx);
            while (true) {
                if (it_set.next()) |set| {
                    //std.debug.print("{s}\n", .{set});
                    //split cube
                    try splitMaxCube(set, &cube_set_mx);
                } else {
                    break;
                }
            }
            sum += (cube_set_mx.cubeG.size * cube_set_mx.cubeR.size * cube_set_mx.cubeB.size);
        } else {
            break;
        }
    }
    return sum;
}

fn splitCube(set: []const u8) !bool {
    var it_cube = splitSeq(u8, set, ", ");
    //split number and color
    var it_divide_f = splitSca(u8, it_cube.first(), ' ');
    const size = try parseInt(usize, it_divide_f.first(), 10);
    const cube_f = .{ .size = size, .cube = it_divide_f.rest() };
    const flag = isPossible(cube_f);
    if (flag) {
        while (true) {
            if (it_cube.next()) |cube| {
                //split number and color
                var it_divide = splitSca(u8, cube, ' ');
                const size_s = try parseInt(usize, it_divide.first(), 10);
                const cube_r = .{ .size = size_s, .cube = it_divide.rest() };
                const flag_r = isPossible(cube_r);
                if (!flag_r) {
                    return false;
                }
            } else {
                return true;
            }
        }
    } else {
        return false;
    }
}

fn splitMaxCube(set: []const u8, cube_set: *CubeSet) !void {
    var it_cube = splitSeq(u8, set, ", ");
    //split number and color
    var it_divide_f = splitSca(u8, it_cube.first(), ' ');
    const size = try parseInt(usize, it_divide_f.first(), 10);
    const cube_f = .{ .size = size, .cube = it_divide_f.rest() };
    maxCubeSet(cube_set, cube_f);
    while (true) {
        if (it_cube.next()) |cube| {
            //split number and color
            var it_divide = splitSca(u8, cube, ' ');
            const size_s = try parseInt(usize, it_divide.first(), 10);
            const cube_r = .{ .size = size_s, .cube = it_divide.rest() };
            maxCubeSet(cube_set, cube_r);
        } else {
            break;
        }
    }
}

fn maxCubeSet(cube_set: *CubeSet, cube: CubeMap) void {
    if (std.mem.eql(u8, cube.cube, "blue")) {
        if (cube.size > cube_set.cubeB.size) {
            cube_set.cubeB.size = cube.size;
        }
    } else if (std.mem.eql(u8, cube.cube, "red")) {
        if (cube.size > cube_set.cubeR.size) {
            cube_set.cubeR.size = cube.size;
        }
    } else {
        if (cube.size > cube_set.cubeG.size) {
            cube_set.cubeG.size = cube.size;
        }
    }
}

fn isPossible(cube: CubeMap) bool {
    if (std.mem.eql(u8, cube.cube, "blue")) {
        if (cube.size > 14) {
            return false;
        } else {
            return true;
        }
    } else if (std.mem.eql(u8, cube.cube, "red")) {
        if (cube.size > 12) {
            return false;
        } else {
            return true;
        }
    } else {
        if (cube.size > 13) {
            return false;
        } else {
            return true;
        }
    }
}

test "part1 example" {
    const doc =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;
    const sum: usize = try getGameIdSum(doc);
    try std.testing.expect(sum == 8);
}

test "part2 example" {
    const doc =
        \\Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
        \\Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
        \\Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
        \\Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
        \\Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green
    ;
    const sum: usize = try getMxGameIdSum(doc);
    try std.testing.expect(sum == 2286);
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
