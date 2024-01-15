const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day04.txt");

pub fn main() !void {
    const part_one = try sumPoints(data);
    std.debug.print("part_one={d}\n", .{part_one});
}

fn sumPoints(doc: []const u8) !usize {
    var stream = std.io.fixedBufferStream(doc);
    var buf: [1024]u8 = undefined;
    var sum: usize = 0;
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            var size: usize = 0;
            var it = std.mem.splitSequence(u8, line, " | ");
            var win_nums = std.mem.splitSequence(u8, it.first(), ": ");
            _ = win_nums.first();
            var it_win = std.mem.splitSequence(u8, win_nums.rest(), " ");
            while (it_win.next()) |win_num| {
                if (std.mem.eql(u8, win_num, "")) {
                    continue;
                }
                var it_chars = std.mem.splitSequence(u8, it.rest(), " ");
                while (it_chars.next()) |it_char| {
                    if (std.mem.eql(u8, win_num, "")) {
                        continue;
                    }
                    if (std.mem.eql(u8, it_char, win_num)) {
                        size += 1;
                    }
                }
            }
            var all: usize = 1;
            if (size == 0) {
                all = 0;
            }
            while (size > 1) {
                all *= 2;
                size -= 1;
            }
            sum += all;
        } else {
            break;
        }
    }
    return sum;
}

test "part one example" {
    const doc =
        \\Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53
        \\Card 2: 13 32 20 16 61 | 61 30 68 82 17 32 24 19
        \\Card 3:  1 21 53 59 44 | 69 82 63 72 16 21 14  1
        \\Card 4: 41 92 73 84 69 | 59 84 76 51 58  5 54 83
        \\Card 5: 87 83 26 28 32 | 88 30 70 12 93 22 82 36
        \\Card 6: 31 18 13 56 72 | 74 77 10 23 35 67 36 11
    ;
    try std.testing.expect(try sumPoints(doc) == 13);
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
