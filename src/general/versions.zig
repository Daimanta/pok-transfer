const std = @import("std");
const gen1 = @import("../gen1/save_datastructure.zig");
const gen2 = @import("../gen2GS/save_datastructure.zig");

pub const UnknownVersionError = error{UnknownVersion};

pub const Version = enum {
    GEN1,
    GEN2GS,
    GEN3FRLG
};

pub fn determineVersion(bytes: []const u8) UnknownVersionError!Version {
    const length = bytes.len;
    if (length == 1 << 15) {
        if (gen1.checksums_are_valid(bytes[0..gen1.save_size])) {
            return .GEN1;
        }
        return UnknownVersionError.UnknownVersion;
    } else if (length >= gen2.save_size and length <= gen2.save_size + gen2.rtc_margin) {
        if (gen2.checksums_are_valid(bytes[0..gen2.save_size])) {
            return .GEN2GS;
        }
        return UnknownVersionError.UnknownVersion;
    } else {
        return UnknownVersionError.UnknownVersion;
    }
}