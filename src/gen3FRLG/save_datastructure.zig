const std = @import("std");

pub const save_copy_size = 57344;
pub const section_size = 4096;

pub const section_id_offset = 0x0FF4;
pub const checksum_offset = 0x0FF6;
pub const signature_offset = 0x0FF8;
pub const save_index_offset = 0x0FFC;

pub const trainer_section_id = 0;
pub const party_section_id = 1;
pub const first_box_section_id = 5;
pub const last_fullsize_box_section_id = 12;
pub const last_box_section_id = 13;

pub const box_section_size = 3968;
pub const last_box_section_size = 2000;
pub const boxes_total_size = 33744;

pub const party_offset = 0x0034;
pub const party_size = 1528;


pub const StrippedMonData = struct {
    personality_value: u32,
    ot_id: u32,
    nickname: [10]u8,
    language: u8,
    misc_flags: u8,
    ot_name: [7]u8,
    markings: u8,
    checksum: u16,
    unknown0: u16,
    data: [48]u8
};

pub const MonData = struct {
    stripped_mon_data: StrippedMonData,
    status_condition: u32,
    level: u8,
    mail_id: u8,
    current_hp: u16,
    total_hp: u16,
    attack: u16,
    defense: u16,
    speed: u16,
    special_attack: u16,
    special_defense: u16
};

pub const FullPartyData = struct {
    number_of_mon: u8,
    mons: [6]MonData
};

pub fn getLatestSave(bytes: []const u8) u1 {
    const save0: u16 = @bitCast(bytes[save_index_offset..save_index_offset + 2].*);
    const save1: u16 = @bitCast(bytes[save_copy_size + save_index_offset..save_copy_size + save_index_offset + 2].*);
    if (save0 > save1) {
        return 0;
    } else {
        return 1;
    }
}

pub fn getSectionId(bytes: []const u8, start: usize) u16 {
    return @bitCast(bytes[start + section_id_offset .. start + section_id_offset + 2][0..2].*);
}

pub fn getSectionStart(bytes: []const u8, section_number: u8) usize {
    const latest_save = getLatestSave(bytes);
    const first_section_number = getSectionId(bytes, @as(u16, latest_save) * save_copy_size);
    if (first_section_number <= section_number) {
        return (@as(usize, latest_save) * save_copy_size) + ((section_number - first_section_number) * section_size);
    } else {
        return (@as(usize, latest_save) * save_copy_size) + ((14 - (first_section_number - section_number) ) * section_size);
    }
}

pub fn getBoxBytes(bytes: []const u8) [boxes_total_size]u8 {
    var result: [boxes_total_size]u8 = undefined;

    var i: usize = first_box_section_id;
    var moved: usize = 0;
    while (i <= last_fullsize_box_section_id ): ( i += 1 ) {
        const section_start = getSectionStart(bytes, i);
        std.mem.copyForwards(u8, result[moved..moved + box_section_size], bytes[section_start..section_start + box_section_size]);
        moved += box_section_size;
    }
    const last_section_start = getSectionStart(bytes, last_box_section_id);
    std.mem.copyForwards(u8, result[moved..moved + last_box_section_size], bytes[last_section_start..last_section_start + last_box_section_size]);

    return result;
}

