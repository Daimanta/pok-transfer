const std = @import("std");

pub const encoding_table: [256][]const u8 = .{
    "\x00", "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    " ",
    "A",    "B",  "C",  "D", "E",  "F",   "G", "H", "I", "J",   "K",   "L",   "M",   "N",   "O",   "P",
    "Q",    "R",  "S",  "T", "U",  "V",   "W", "X", "Y", "Z",   "(",   ")",   ":",   ";",   "[",   "]",
    "a",    "b",  "c",  "d", "e",  "f",   "g", "h", "i", "j",   "k",   "l",   "m",   "n",   "o",   "p",
    "q",    "r",  "s",  "t", "y",  "v",   "w", "x", "y", "z",   "é",  "'d",  "'l",  "'s",  "'t",  "'v",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "'",    "PK", "MN", "-", "'r", "'m",  "?", "!", ".", "ァ", "ゥ", "ェ", "▷", "▶", "▼", "♂",
    "P",    "×", ".",  "/", ",",  "♀", "0", "1", "2", "3",   "4",   "5",   "6",   "7",   "8",   "9",
};

pub fn genItoUtf8(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var buffer: [1024]u8 = undefined;
    var current_size: usize = 0;
    for (input) |byte| {
        const val = encoding_table[byte];
        if (byte < 0x5F) break;
        std.mem.copyForwards(u8, buffer[current_size..], val);
        current_size += val.len;
    }
    return allocator.dupe(u8, buffer[0..current_size]);
}

pub fn utf8ToGenI(input: []const u8) [11]u8{
    var result: [11]u8 = std.mem.zeroes([11]u8);
    var current: usize = 0;
    var result_index: usize = 0;
    while (current < input.len) {
        if (input[current] >= 'A' and input[current] <= 'Z') {
            result[result_index] = 0x80 + input[current] - 'A';
            current += 1;
        } else if (input[current] >= 'a' and input[current] <= 'z') {
            result[result_index] = 0xA0 + input[current] - 'a';
            current += 1;
        } else if (input[current] == '(') {
            result[result_index] = 0x9A;
            current += 1;
        } else if (input[current] == ')') {
            result[result_index] = 0x9B;
            current += 1;
        } else if(input[current] >= '0' and input[current] <= '9') {
            result[result_index] = 0xF6 + input[current] - '0';
            current += 1;
        } else if (input[current] == '.') {
            result[result_index] = 0xF2;
            current += 1;
        } else if (input[current] == '/') {
            result[result_index] = 0xF3;
            current += 1;
        } else if (input[current] == ',') {
            result[result_index] = 0xF4;
            current += 1;
        } else if (input[current] == '?') {
            result[result_index] = 0xE6;
            current += 1;
        } else if (input[current] == '!') {
            result[result_index] = 0xE7;
            current += 1;
        } else if (input[current] == '\xE2' and input[current + 1] == '\x99' and input[current + 2] == '\x80') {
            result[result_index] = 0xF5;
            current += 3;
        } else if (input[current] == '\xE2' and input[current + 1] == '\x99' and input[current + 2] == '\x82') {
            result[result_index] = 0xEF;
            current += 3;
        } else if (input[current] == '\xC3' and input[current + 1] == '\xA9') {
            result[result_index] = 0xE6;
            current += 2;
        } else if (input[current] == ' ') {
            result[result_index] = 0x7F;
            current += 1;
        } else {
            result[result_index] = 0xE6; // '?'
            current += 1;
        }

        result_index += 1;
    }

    while (result_index < 11): (result_index += 1) {
        result[result_index] = 0x50; // sentinel at the end
    }
    return result;
}