const std = @import("std");
const Allocator = std.mem.Allocator;
const List = std.ArrayList;
const Map = std.AutoHashMap;
const StrMap = std.StringHashMap;
const BitSet = std.DynamicBitSet;

const util = @import("util.zig");
const gpa = util.gpa;

const data = @embedFile("data/day07.txt");

pub fn main() !void {
    const part_one = try sumWin(data);
    std.debug.print("part_one={d}\n", .{part_one});
}

const Win = struct {
    hand: []const u8,
    bid: usize,
};

const order = [13]u8{
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'T',
    'J',
    'Q',
    'K',
    'A',
};

fn isBigger(hand_1: []const u8, hand_2: []const u8) !bool {
    var buf: [104]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var hash_1 = std.AutoHashMap(u8, void).init(fba.allocator());
    defer hash_1.deinit();
    var hash_2 = std.AutoHashMap(u8, void).init(fba.allocator());
    defer hash_2.deinit();
    for (hand_1) |card| {
        try hash_1.put(card, {});
    }
    for (hand_2) |card| {
        try hash_2.put(card, {});
    }
    if (hash_1.count() > hash_2.count()) {
        return false;
    } else if (hash_1.count() == hash_2.count()) {
        var key_1 = hash_1.keyIterator();
        var muti_1: usize = 1;
        while (key_1.next()) |key| {
            muti_1 *= std.mem.count(u8, hand_1, &[_]u8{key.*});
        }
        var key_2 = hash_2.keyIterator();
        var muti_2: usize = 1;
        while (key_2.next()) |key| {
            muti_2 *= std.mem.count(u8, hand_2, &[_]u8{key.*});
        }
        if (muti_1 < muti_2) {
            return true;
        } else if (muti_1 == muti_2) {
            // order
            for (hand_1, hand_2) |card_1, card_2| {
                var index_1: usize = 13;
                var index_2: usize = 13;
                for (order, 0..) |card, i| {
                    if (std.mem.eql(u8, &[_]u8{card}, &[_]u8{card_1})) {
                        index_1 = i;
                    }
                    if (std.mem.eql(u8, &[_]u8{card}, &[_]u8{card_2})) {
                        index_2 = i;
                    }
                    if (index_1 != 13 and index_2 != 13) {
                        break;
                    }
                }
                if (index_1 > index_2) {
                    return true;
                } else if (index_1 < index_2) {
                    return false;
                } else {}
            }
            return false;
        } else {
            return false;
        }
    } else {
        return true;
    }
}

fn sumWin(doc: []const u8) !usize {
    var buf: [1024]u8 = undefined;
    var stream = std.io.fixedBufferStream(doc);
    var buf_win: [1024 * 1024]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf_win);
    var win_arry = std.ArrayList(Win).init(fba.allocator());
    defer win_arry.deinit();
    while (true) {
        const line_maybe = try stream.reader().readUntilDelimiterOrEof(&buf, '\n');
        if (line_maybe) |line| {
            var split = std.mem.splitSequence(u8, line, " ");
            const hand_key = split.first();
            const bid = try std.fmt.parseInt(usize, split.rest(), 10);
            if (win_arry.items.len == 0) {
                try win_arry.append(.{
                    .hand = try fba.allocator().dupe(u8, hand_key),
                    .bid = bid,
                });
            } else {
                for (0..win_arry.items.len) |i| {
                    if (i + 1 < win_arry.items.len) {
                        if ((try isBigger(hand_key, win_arry.items[i].hand) and
                            !try isBigger(hand_key, win_arry.items[i + 1].hand)) or
                            (i == 0 and !try isBigger(hand_key, win_arry.items[i].hand)))
                        {
                            var pos: usize = i + 1;
                            if (i == 0 and !try isBigger(hand_key, win_arry.items[i].hand)) {
                                pos = 0;
                            }
                            try win_arry.insert(pos, .{
                                .hand = try fba.allocator().dupe(u8, hand_key),
                                .bid = bid,
                            });
                            break;
                        }
                    } else {
                        try win_arry.append(.{
                            .hand = try fba.allocator().dupe(u8, hand_key),
                            .bid = bid,
                        });
                    }
                }
            }
        } else {
            break;
        }
    }
    var winning_sum: usize = 0;
    for (win_arry.items, 0..) |winning, i| {
        winning_sum += winning.bid * (i + 1);
    }
    return winning_sum;
}

test "part one example" {
    const doc =
        \\32T3K 765
        \\T55J5 684
        \\KK677 28
        \\KTJJT 220
        \\QQQJA 483
    ;
    try std.testing.expect(try sumWin(doc) == 6440);
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
