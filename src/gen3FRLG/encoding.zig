const std = @import("std");

pub const encoding_table: [256][]const u8 = .{
    " ", "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "",     "",   "",   "",  "",   "",    "",  "",  "",  "",    "",    "",    "",    "",    "",    "",
    "a",    "0",  "1",  "2", "3",  "4",   "5", "6", "7", "8",   "9",   "!",   "?",   ".",   "-",   "-",
    "..",   "\"", "\"", "'", "'",  "♂",   "♀", "P", ",", "x",   "/",    "A",  "B",  "C",  "D",  "E",
    "F",    "G",  "H",  "I", "J",  "K",   "L",  "M",  "N",  "O",   "P",    "Q",    "R",    "S",    "T",    "U",
    "V", "W", "X",  "Y",  "Z", "a", "b",  "c",  "d",  "e",  "f", "g",  "h",    "i",    "j",    "k",
    "l",  "m", "n", "o", "p", "q",  "r", "s", "t", "u", "v", "w", "x", "y", "z", "▶",
    ":",  "Ä", "Ö",  "Ü", "ä",  "ö", "ü", "", "", "",   "",   "", "",   "",   "",   "",
};

pub const linebreak = 0xFE;
pub const terminator = 0xFF;

pub fn gen3toUtf8(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
    var buffer: [1024]u8 = undefined;
    var current_size: usize = 0;
    for (input) |byte| {
        const val = encoding_table[byte];
        if (byte == terminator) break;
        std.mem.copyForwards(u8, buffer[current_size..], val);
        current_size += val.len;
    }
    return allocator.dupe(u8, buffer[0..current_size]);
}

pub fn utf8ToGen3(input: []const u8) [10]u8 {
    var result: [10]u8 = .{terminator} ** 10;
    var result_idx: usize = 0;
    const utf8_view = std.unicode.Utf8View.init(input) catch {unreachable;};
    var iterator = std.unicode.Utf8View.iterator(utf8_view);
    while (true) {
        const codepoint_opt = iterator.nextCodepoint();
        if (codepoint_opt == null) break;
        const codepoint = codepoint_opt.?;
        if (codepoint >= 65 and codepoint <= 90) {
            //capitals
            result[result_idx] = @intCast(0xBB + (codepoint - 65));
        } else if (codepoint >= 97 and codepoint <= 122) {
            // lowercase letters
            result[result_idx] = @intCast(0xD5 + (codepoint - 97));
        } else if (codepoint >= 48 and codepoint <= 57) {
            result[result_idx] = @intCast(0xA1 + (codepoint - 48));
        } else if (codepoint == '!') {
            result[result_idx] = 0xAB;
        } else if (codepoint == '?') {
            result[result_idx] = 0xAC;
        } else if (codepoint == ',') {
            result[result_idx] = 0xB8;
        } else if (codepoint == '/') {
            result[result_idx] = 0xBA;
        } else if (codepoint == '.') {
            result[result_idx] = 0xAD;
        } else if (codepoint == '-') {
            result[result_idx] = 0xAE;
        } else if (codepoint == 9794) {// ♂
            result[result_idx] = 0xB5;
        } else if (codepoint == 9792) { // ♀
            result[result_idx] = 0xB6;
        } else if (codepoint == 196) { // Ä
            result[result_idx] = 0xF1;
        } else if (codepoint == 214) { // Ö
            result[result_idx] = 0xF2;
        } else if (codepoint == 220) { // Ü
            result[result_idx] = 0xF3;
        } else if (codepoint == 228) { // ä
            result[result_idx] = 0xF4;
        } else if (codepoint == 246) { // ö
            result[result_idx] = 0xF5;
        } else if (codepoint == 252) { // ü
            result[result_idx] = 0xF6;
        } else {
            result[result_idx] = 0xAC; // ?
        }
        result_idx += 1;
    }
    return result;
}
