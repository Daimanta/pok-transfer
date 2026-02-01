const std = @import("std");

pub const save_size = 1 << 15;
pub const rtc_margin = 48;

pub const party_start = 0x288A;
pub const party_size = 428;

pub const current_box_number = 0x2724;

pub const current_box_start = 0x2D6C;

pub const boxes_start = 0x4000;
pub const box_size = 1104;
pub const number_of_boxes = 14;

pub const box_mon_size = 32;

pub const checksum1_area_start = 0x2009;
pub const checksum1_area_end_incl = 0x2D68;
pub const checksum1_start = 0x2D69;
pub const checksum1_size = 2;

pub const checksum2_starts: [3]u16 = .{0x0C6B, 0x3D96, 0x7E39};
pub const checksum2_end_incls: [3]u16 = .{0x17EC, 0x3F3F, 0x7E6C};
pub const checksum2_start = 0x7E6D;
pub const checksum2_size = 2;

pub const MonPP = packed struct {
    current_pp: u6,
    applied_ppup: u2,
};

pub const StrippedMonData = packed struct {
    index_number: u8,
    held_item_number: u8,
    move_1: u8,
    move_2: u8,
    move_3: u8,
    move_4: u8,
    ot_number: u16,
    experience_points: u24,
    hp_ev: u16,
    attack_ev: u16,
    defense_ev: u16,
    speed_ev: u16,
    special_ev: u16,
    iv_attack: u4,
    iv_defense: u4,
    iv_speed: u4,
    iv_special: u4,
    pp_1: MonPP,
    pp_2: MonPP,
    pp_3: MonPP,
    pp_4: MonPP,
    friendship_eggcycles: u8,
    pokerus: u8,
    caught_data: u16,
    level: u8,
};

pub const MonData = packed struct {
    stripped_mon_data: StrippedMonData,
    status_condition: u8,
    padding0: u8 = 255,
    current_hp: u16,
    max_hp: u16,
    attack: u16,
    defense: u16,
    speed: u16,
    special_attack: u16,
    special_defense: u16
};

pub const Name = packed struct {
    byte0: u8, byte1: u8, byte2: u8, byte3: u8, byte4: u8, byte5: u8, byte6: u8, byte7: u8, byte8: u8, byte9: u8, byte10: u8,

    pub fn toBytes(self: @This()) [11]u8 {
        return .{self.byte0, self.byte1, self.byte2, self.byte3, self.byte4, self.byte5, self.byte6, self.byte7, self.byte8, self.byte9, self.byte10};
    }
};

pub const FullBoxDataByteArray = [box_size]u8;

pub const FullBoxData = struct {
    number_of_mon: u8,
    species_id: [20]u8,
    padding0: u8,
    mon: [20]StrippedMonData,
    ot_names: [20][11]u8,
    mon_names: [20][11]u8,
    padding1: [2]u8,

    pub fn init(byte_array: *const FullBoxDataByteArray) FullBoxData {
        var result: FullBoxData = .{
           .number_of_mon = byte_array[0],
           .species_id = byte_array[1..21].*,
           .padding0 = byte_array[21],
           .mon = undefined,
           .ot_names = undefined,
           .mon_names = undefined,
           .padding1 = byte_array[1102..1104].*
        };
        var i: usize = 0;
        while (i < 20): (i += 1) {
            std.mem.copyForwards(u8, @ptrCast(&result.mon[i]), byte_array[22+(i*box_mon_size)..22+(i*box_mon_size) + box_mon_size]);
        }
        std.mem.copyForwards(u8, @ptrCast(&result.ot_names), byte_array[662..882]);
        std.mem.copyForwards(u8, @ptrCast(&result.mon_names), byte_array[882..1102]);
        return result;
    }

    pub fn toFullBoxDataByteArray(self: *const @This()) FullBoxDataByteArray {
        var result: FullBoxDataByteArray = undefined;
        result[0] = self.number_of_mon;
        std.mem.copyForwards(u8, result[1..21], self.species_id[0..]);
        result[21] = self.padding0;
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            const bytes: [box_mon_size]u8 = @bitCast(self.mon[i]);
            std.mem.copyForwards(u8, result[22+(i*box_mon_size)..22+(i*box_mon_size) + box_mon_size], &bytes);
        }
        std.mem.copyForwards(u8, result[662..882], @ptrCast(&self.ot_names));
        std.mem.copyForwards(u8, result[882..1102], @ptrCast(&self.mon_names));
        std.mem.copyForwards(u8, result[1102..1104], self.padding1[0..]);
        return result;
    }
};

pub const FullPartyData = packed struct {
    number_of_mon: u8,
    mon1_species: u8,
    mon2_species: u8,
    mon3_species: u8,
    mon4_species: u8,
    mon5_species: u8,
    mon6_species: u8,
    padding0: u8,
    mon1: MonData,
    mon2: MonData,
    mon3: MonData,
    mon4: MonData,
    mon5: MonData,
    mon6: MonData,
    mon1_ot_name: Name,
    mon2_ot_name: Name,
    mon3_ot_name: Name,
    mon4_ot_name: Name,
    mon5_ot_name: Name,
    mon6_ot_name: Name,
    mon1_name: Name,
    mon2_name: Name,
    mon3_name: Name,
    mon4_name: Name,
    mon5_name: Name,
    mon6_name: Name,

    pub fn getMons(self: @This()) [6]MonData {
        return .{self.mon1, self.mon2, self.mon3, self.mon4, self.mon5, self.mon6};
    }

    pub fn getNames(self: @This()) [6]Name {
        return .{self.mon1_name, self.mon2_name, self.mon3_name, self.mon4_name, self.mon5_name, self.mon6_name};
    }

    pub fn getOtNames(self: @This()) [6]Name {
        return .{self.mon1_ot_name, self.mon2_ot_name, self.mon3_ot_name, self.mon4_ot_name, self.mon5_ot_name, self.mon6_ot_name};
    }
};


pub fn checksums_are_valid(save: *const [save_size]u8) bool {
    return checksum1_isvalid(save) and checksum2_isvalid(save);
}

fn calculate_checksum1(save: *const [save_size]u8) u16{
    var calculated: u16 = 0;

    var i: usize = checksum1_area_start;
    while (i <= checksum1_area_end_incl) : (i += 1) {
        calculated +%= save[i];
    }
    return calculated;
}

fn checksum1_isvalid(save: *const [save_size]u8) bool {
    const expected: u16 = @bitCast(save[checksum1_start..checksum1_start + checksum1_size][0..checksum1_size].*);
    const calculated: u16 = calculate_checksum1(save);
    return expected == calculated;
}

fn calculate_checksum2(save: *const [save_size]u8) u16 {
    var calculated: u16 = 0;
    var i: usize = 0;
    while (i < checksum2_starts.len): (i += 1) {
        var j: usize = checksum2_starts[i];
        while (j <= checksum2_end_incls[i]): (j += 1) {
            calculated +%= save[j];
        }
    }
    return calculated;
}

fn checksum2_isvalid(save: *const [save_size]u8) bool {
    const expected: u16 = @bitCast(save[checksum2_start..checksum2_start + checksum2_size][0..checksum2_size].*);
    const calculated: u16 = calculate_checksum2(save);
    return expected == calculated;
}

pub fn set_checksum(save: *[save_size]u8) void {
    const checksum1 = calculate_checksum1(save);
    const checksum2 = calculate_checksum2(save);
    std.mem.copyForwards(u8, save[checksum1_start..checksum1_start + checksum1_size], &std.mem.toBytes(checksum1));
    std.mem.copyForwards(u8, save[checksum2_start..checksum2_start + checksum2_size], &std.mem.toBytes(checksum2));
}