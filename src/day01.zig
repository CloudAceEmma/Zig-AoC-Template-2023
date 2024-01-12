const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day01.txt");

pub fn main() !void {
    const part1_sum = try getCalibrationSum(data, false);
    print("part1 sum={}\n", .{part1_sum});
    const part2_sum = try getCalibrationSum(data, true);
    print("part2 sum={}\n", .{part2_sum});
}

const LetterMap = struct {
    value: u8,
    letter: []const u8,
};

fn getCalibrationSum(doc: []const u8, letters: bool) !usize {
    const letter_map = [_]LetterMap{
        .{ .value = '1', .letter = "one" },
        .{ .value = '2', .letter = "two" },
        .{ .value = '3', .letter = "three" },
        .{ .value = '4', .letter = "four" },
        .{ .value = '5', .letter = "five" },
        .{ .value = '6', .letter = "six" },
        .{ .value = '7', .letter = "seven" },
        .{ .value = '8', .letter = "eight" },
        .{ .value = '9', .letter = "nine" },
    };
    var sum: usize = 0;
    var stream = std.io.fixedBufferStream(doc);
    var buf: [1024]u8 = undefined;
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            var number: [2]u8 = undefined;
            var index: usize = 0;
            for (line, 0..) |c, i| {
                if (std.ascii.isDigit(c)) {
                    if (index == 0) {
                        number[0] = c;
                        index = index + 1;
                    }
                    number[1] = c;
                } else if (letters) {
                    inner: for (letter_map) |l| {
                        if (i >= l.letter.len - 1) {
                            const len: usize = l.letter.len;
                            const start: usize = i + 1 - len;
                            if (std.mem.eql(u8, line[start..(i + 1)], l.letter)) {
                                if (index == 0) {
                                    number[0] = l.value;
                                    index = index + 1;
                                    break :inner;
                                }
                                number[1] = l.value;
                                break :inner;
                            }
                        }
                    }
                }
            }
            const value = try parseInt(usize, &number, 10);
            sum = sum + value;
        } else {
            break;
        }
    }
    return sum;
}

test "part1 example" {
    const doc =
        \\1abc2
        \\pqr3stu8vwx
        \\a1b2c3d4e5f
        \\treb7uchet
    ;
    const sum: usize = try getCalibrationSum(doc, false);
    try std.testing.expect(sum == 142);
}

test "part2 example" {
    const doc =
        \\two1nine
        \\eightwothree
        \\abcone2threexyz
        \\xtwone3four
        \\4nineeightseven2
        \\zoneight234
        \\7pqrstsixteen
    ;
    const sum: usize = try getCalibrationSum(doc, true);
    try std.testing.expect(sum == 281);
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
