const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day06.txt");

pub fn main() !void {
    const part_one = try multiWays(data);
    std.debug.print("part_one={d}\n", .{part_one});
    const part_tow = try multiWaysOne(data);
    std.debug.print("part_tow={d}\n", .{part_tow});
}

fn multiWays(doc: []const u8) !usize {
    var buf: [1024]u8 = undefined;
    var stream = std.io.fixedBufferStream(doc);
    var time_buf: [1024]usize = undefined;
    var time_index: usize = 0;
    var distance_buf: [1024]usize = undefined;
    var distance_index: usize = 0;
    var is_time_line = true;
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            if (is_time_line) {
                is_time_line = false;
                var it_time = std.mem.splitSequence(u8, std.mem.trimLeft(u8, line, "Time:      "), " ");
                while (it_time.next()) |time_str| {
                    if (std.mem.eql(u8, time_str, "")) {
                        continue;
                    }
                    time_buf[time_index] = try std.fmt.parseInt(usize, time_str, 10);
                    time_index += 1;
                }
            } else {
                var it_distance = std.mem.splitSequence(u8, std.mem.trimLeft(u8, line, "Distance:  "), " ");
                while (it_distance.next()) |distance_str| {
                    if (std.mem.eql(u8, distance_str, "")) {
                        continue;
                    }
                    distance_buf[distance_index] = try std.fmt.parseInt(usize, distance_str, 10);
                    distance_index += 1;
                }
            }
        } else {
            break;
        }
    }
    var multi: usize = 1;
    for (0..time_index) |t_i| {
        var count: usize = 0;
        for (0..time_buf[t_i] + 1) |i| {
            if (i * (time_buf[t_i] - i) > distance_buf[t_i]) {
                count += 1;
            }
        }
        if (count == 0) {
            count = 1;
        }
        multi *= count;
    }
    return multi;
}

fn multiWaysOne(doc: []const u8) !usize {
    var buf: [1024]u8 = undefined;
    var stream = std.io.fixedBufferStream(doc);
    var time: usize = 0;
    var distance: usize = 0;
    var is_time_line = true;
    var time_buf: [1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&time_buf);
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            if (is_time_line) {
                is_time_line = false;
                var it_time = std.mem.tokenizeScalar(u8, std.mem.trimLeft(u8, line, "Time:      "), ' ');
                var time_array = std.ArrayList([]const u8).init(fba.allocator());
                defer time_array.deinit();
                while (it_time.next()) |ti| {
                    try time_array.appendSlice(&[_][]const u8{ti});
                }
                const time_str = try std.mem.concat(fba.allocator(), u8, time_array.items);
                time = try std.fmt.parseInt(usize, time_str, 10);
            } else {
                var it_distance = std.mem.tokenizeScalar(u8, std.mem.trimLeft(u8, line, "Distance:  "), ' ');
                var distance_array = std.ArrayList([]const u8).init(fba.allocator());
                defer distance_array.deinit();
                while (it_distance.next()) |di| {
                    try distance_array.appendSlice(&[_][]const u8{di});
                }
                const distance_str = try std.mem.concat(fba.allocator(), u8, distance_array.items);
                distance = try std.fmt.parseInt(usize, distance_str, 10);
            }
        } else {
            break;
        }
    }
    var count: usize = 0;
    for (0..time + 1) |i| {
        if (i * (time - i) > distance) {
            count += 1;
        }
    }
    return count;
}

test "part one example" {
    const doc =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;
    try std.testing.expect(try multiWays(doc) == 288);
}

test "part two example" {
    const doc =
        \\Time:      7  15   30
        \\Distance:  9  40  200
    ;
    try std.testing.expect(try multiWaysOne(doc) == 71503);
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
