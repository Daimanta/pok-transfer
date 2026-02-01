const std = @import("std");

pub const save_size = 1 << 15;

pub const trainer_name = 0x2598;
pub const trainer_name_size = 0xb;

pub const rival_name = 0x25F6;
pub const rival_name_size = 0xb;

pub const first_picked_mon = 0x29C3;
pub const first_picked_mon_size = 1;

pub const party = 0x2F2C;
pub const party_size = 0x194;

pub const current_box_start = 0x284C;
pub const current_box_size = 2;

pub const box_copy = 0x30C0;

pub const box_starts :[12]usize = .{0x4000, 0x4462, 0x48C4, 0x4D26, 0x5188, 0x55EA, 0x6000, 0x6462, 0x68C4, 0x6D26, 0x7188, 0x75EA};
pub const box_size = 0x462;

pub const bank1_checksum_range_start = 0x2598;
pub const bank1_checksum_range_end_excl = 0x3523;
pub const bank1_checksum_start = 0x3523;

pub const bank2_checksum_start = 0x5A4C;
pub const bank2_individual_checksum_start = 0x5A4D;
pub const bank2_individual_checksum_size = 6;

pub const bank3_checksum_start = 0x7A4C;
pub const bank3_individual_checksum_start = 0x7A4D;
pub const bank3_individual_checksum_size = 6;

pub const MonType = enum(u8) { NORMAL = 0, FIGHTING = 1, FLYING = 2, POISON = 3, GROUND = 4, ROCK = 5, BIRD = 6, BUG = 7, GHOST = 8, FIRE = 20, WATER = 21, GRASS = 22, ELECTRIC = 23, PSYCHIC = 24, ICE = 25, DRAGON = 26 };

pub const FullBoxDataByteArray = [box_size]u8;

pub const FullBoxData = struct {
    number_of_mon: u8,
    species_id: [20]u8,
    padding0: u8,
    mon: [20]StrippedMonData,
    ot_names: [20][11]u8,
    mon_names: [20][11]u8,

    pub fn init(byte_array: FullBoxDataByteArray) @This() {
        var curr_box_size = byte_array[0];
        if (curr_box_size == 255) {
            curr_box_size = 0;
        }
        var result: FullBoxData = .{
            .number_of_mon = curr_box_size,
            .species_id = undefined,
            .padding0 = undefined,
            .mon = undefined,
            .ot_names = undefined,
            .mon_names = undefined,
        };
        std.mem.copyForwards(u8, &result.species_id, byte_array[1..21]);
        var i: usize = 0;
        while (i < curr_box_size) : (i += 1) {
            std.mem.copyForwards(u8, @ptrCast(&result.mon[i]), byte_array[0x16+(i*33)..0x16+(i*33) + 33]);
        }
        std.mem.copyForwards(u8, @ptrCast(&result.ot_names), byte_array[0x2AA..0x386]);
        std.mem.copyForwards(u8, @ptrCast(&result.mon_names), byte_array[0x386..0x386+(0xB*20)]);
        return result;
    }

    pub fn toFullBoxDataByteArray(self: @This()) FullBoxDataByteArray {
        var result: FullBoxDataByteArray = undefined;
        result[0] = self.number_of_mon;
        std.mem.copyForwards(u8, result[1..1 + 20], &self.species_id);
        result[21] = self.padding0;
        var i: usize = 0;
        while (i < self.number_of_mon) : (i += 1) {
            var bytes: [33]u8 = @bitCast(self.mon[i]);
            std.mem.copyForwards(u8, result[0x16+(i*33)..0x16+(i*33) + 33], &bytes);
        }
        std.mem.copyForwards(u8, result[0x2AA..0x386], @ptrCast(&self.ot_names));
        std.mem.copyForwards(u8, result[0x386..0x386+(0xB*20)], @ptrCast(&self.mon_names));
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

pub const species_start = 0x0383DE;
pub const mew_start = 0x00425B;

pub const MonSpecies = packed struct {
    dex_number: u8,
    hp: u8,
    attack: u8,
    defense: u8,
    speed: u8,
    special: u8,
    type1: u8,
    type2: u8,
    catch_rate: u8,
    exp_yield: u8,
    frontsprite_dims: u8,
    frontsprite_ptr: u16,
    backsprite_ptr: u16,
    attacks1: u8,
    attacks2: u8,
    attacks3: u8,
    attacks4: u8,
    growth_rate: u8,
    tm_hm_flags1: u8,
    tm_hm_flags2: u8,
    tm_hm_flags3: u8,
    tm_hm_flags4: u8,
    tm_hm_flags5: u8,
    tm_hm_flags6: u8,
    tm_hm_flags7: u8,
    padding0: u8
};

pub const MonData = packed struct { strippedMonData: StrippedMonData, level: u8, max_hp: u16, attack: u16, defense: u16, speed: u16, special: u16 };
pub const StrippedMonData = packed struct { index_number: u8, hp: u16, level_repr: u8, status_condition: u8, type1: u8, type2: u8, catch_rate_held_item: u8, move_1: u8, move_2: u8, move_3: u8, move_4: u8, original_trainer_number: u16, experience_points: u24, hp_ev: u16, attack_ev: u16, defense_ev: u16, speed_ev: u16, special_ev: u16, iv_1: u4, iv_2: u4, iv_3: u4, iv_4: u4, pp_1: MonPP, pp_2: MonPP, pp_3: MonPP, pp_4: MonPP };

pub const MonPP = packed struct {
    current_pp: u6,
    applied_ppup: u2,
};

pub const Name = packed struct { byte0: u8, byte1: u8, byte2: u8, byte3: u8, byte4: u8, byte5: u8, byte6: u8, byte7: u8, byte8: u8, byte9: u8, byte10: u8,

    pub fn toBytes(self: @This()) [11]u8 {
        return .{self.byte0, self.byte1, self.byte2, self.byte3, self.byte4, self.byte5, self.byte6, self.byte7, self.byte8, self.byte9, self.byte10};
    }
};

pub fn getNameBytes(bytes: []const u8) []const u8 {
    return bytes[trainer_name .. trainer_name + trainer_name_size];
}

pub fn toNationalDexNumber(gen1number: u8) u8{
    return switch (gen1number) {
        1 => 112,
        2 => 115,
        3 => 32,
        4 => 35,
        5 => 21,
        6 => 100,
        7 => 34,
        8 => 80,
        9 => 2,
        10 => 103,
        11 => 108,
        12 => 102,
        13 => 88,
        14 => 94,
        15 => 29,
        16 => 31,
        17 => 104,
        18 => 111,
        19 => 131,
        20 => 59,
        21 => 151,
        22 => 130,
        23 => 90,
        24 => 72,
        25 => 92,
        26 => 123,
        27 => 120,
        28 => 9,
        29 => 127,
        30 => 114, // gap after this entry
        33 => 58,
        34 => 95,
        35 => 22,
        36 => 16,
        37 => 79,
        38 => 64,
        39 => 75,
        40 => 113,
        41 => 67,
        42 => 122,
        43 => 106,
        44 => 107,
        45 => 24,
        46 => 47,
        47 => 54,
        48 => 96,
        49 => 76, // gap after this entry
        51 => 126, // gap after this entry
        53 => 125,
        54 => 82,
        55 => 109, // gap after this entry
        57 => 56,
        58 => 86,
        59 => 50,
        60 => 128, // gap after this entry
        64 => 83,
        65 => 48,
        66 => 149, // gap after this entry
        70 => 84,
        71 => 60,
        72 => 124,
        73 => 146,
        74 => 144,
        75 => 145,
        76 => 132,
        77 => 52,
        78 => 98, // gap after this entry
        82 => 37,
        83 => 38,
        84 => 25,
        85 => 26, // gap after this entry
        88 => 147,
        89 => 148,
        90 => 140,
        91 => 141,
        92 => 116,
        93 => 117, // gap after this entry
        96 => 27,
        97 => 28,
        98 => 138,
        99 => 139,
        100 => 39,
        101 => 40,
        102 => 133,
        103 => 136,
        104 => 135,
        105 => 134,
        106 => 66,
        107 => 41,
        108 => 23,
        109 => 46,
        110 => 61,
        111 => 62,
        112 => 13,
        113 => 14,
        114 => 15, // gap after this entry
        116 => 85,
        117 => 57,
        118 => 51,
        119 => 49,
        120 => 87, // gap after this entry
        123 => 10,
        124 => 11,
        125 => 12,
        126 => 68, // gap after this entry
        128 => 55,
        129 => 97,
        130 => 42,
        131 => 150,
        132 => 143,
        133 => 129, // gap after this entry
        136 => 89, // gap after this entry
        138 => 99,
        139 => 91, // gap after this entry
        141 => 101,
        142 => 36,
        143 => 110,
        144 => 53,
        145 => 105, // gap after this entry
        147 => 93,
        148 => 63,
        149 => 65,
        150 => 17,
        151 => 18,
        152 => 121,
        153 => 1,
        154 => 3,
        155 => 73, // gap after this entry
        157 => 118,
        158 => 119,
        163 => 77,
        164 => 78,
        165 => 19,
        166 => 20,
        167 => 33,
        168 => 30,
        169 => 74,
        170 => 137,
        171 => 142, // gap after this entry
        173 => 81, // gap after this entry
        176 => 4,
        177 => 7,
        178 => 5,
        179 => 8,
        180 => 6, // gap after this entry
        185 => 43,
        186 => 44,
        187 => 45,
        188 => 69,
        189 => 70,
        190 => 71,
        else => 0
    };
}

pub fn gen1NumberFromNationalDexNumber(dex_number: u8) u8{
    return switch (dex_number) {
        1 => 153,
        2 => 9,
        3 => 154,
        4 => 176,
        5 => 178,
        6 => 180,
        7 => 177,
        8 => 179,
        9 => 28,
        10 => 123,
        11 => 124,
        12 => 125,
        13 => 112,
        14 => 113,
        15 => 114,
        16 => 36,
        17 => 150,
        18 => 151,
        19 => 165,
        20 => 166,
        21 => 5,
        22 => 35,
        23 => 108,
        24 => 45,
        25 => 84,
        26 => 85,
        27 => 96,
        28 => 97,
        29 => 15,
        30 => 168,
        31 => 16,
        32 => 3,
        33 => 167,
        34 => 7,
        35 => 4,
        36 => 142,
        37 => 82,
        38 => 83,
        39 => 100,
        40 => 101,
        41 => 107,
        42 => 130,
        43 => 185,
        44 => 186,
        45 => 187,
        46 => 109,
        47 => 46,
        48 => 65,
        49 => 119,
        50 => 59,
        51 => 118,
        52 => 77,
        53 => 144,
        54 => 47,
        55 => 128,
        56 => 57,
        57 => 117,
        58 => 33,
        59 => 20,
        60 => 71,
        61 => 110,
        62 => 111,
        63 => 148,
        64 => 38,
        65 => 149,
        66 => 106,
        67 => 41,
        68 => 126,
        69 => 188,
        70 => 189,
        71 => 190,
        72 => 24,
        73 => 155,
        74 => 169,
        75 => 39,
        76 => 49,
        77 => 163,
        78 => 164,
        79 => 37,
        80 => 8,
        81 => 173,
        82 => 54,
        83 => 64,
        84 => 70,
        85 => 116,
        86 => 58,
        87 => 120,
        88 => 13,
        89 => 136,
        90 => 23,
        91 => 139,
        92 => 25,
        93 => 147,
        94 => 14,
        95 => 34,
        96 => 48,
        97 => 129,
        98 => 78,
        99 => 138,
        100 => 6,
        101 => 141,
        102 => 12,
        103 => 10,
        104 => 17,
        105 => 145,
        106 => 43,
        107 => 44,
        108 => 11,
        109 => 55,
        110 => 143,
        111 => 18,
        112 => 1,
        113 => 40,
        114 => 30,
        115 => 2,
        116 => 92,
        117 => 93,
        118 => 157,
        119 => 158,
        120 => 27,
        121 => 152,
        122 => 42,
        123 => 26,
        124 => 72,
        125 => 53,
        126 => 51,
        127 => 29,
        128 => 60,
        129 => 133,
        130 => 22,
        131 => 19,
        132 => 76,
        133 => 102,
        134 => 105,
        135 => 104,
        136 => 103,
        137 => 170,
        138 => 98,
        139 => 99,
        140 => 90,
        141 => 91,
        142 => 171,
        143 => 132,
        144 => 74,
        145 => 75,
        146 => 73,
        147 => 88,
        148 => 89,
        149 => 66,
        150 => 131,
        151 => 21,
        else => 0
    };
}

fn bank_checksum(save: *const [save_size]u8, start: usize, end_excl: usize) u8 {
    var result: u8 = 0;
    var i: usize = start;
    while (i < end_excl): (i += 1) {
        result +%= save[i];
    }
    result = ~result;
    return result;
}

pub fn checksums_are_valid(save: *const [save_size]u8) bool {
    return bank1_checksum_is_valid(save) and bank2_checksum_is_valid(save) and bank3_checksum_is_valid(save);
}

pub fn bank1_checksum_is_valid(save: *const [save_size]u8) bool{
    const expected = save[bank1_checksum_start];
    const calculated = bank_checksum(save, bank1_checksum_range_start, bank1_checksum_range_end_excl);
    return calculated == expected;
}

pub fn bank2_checksum_is_valid(save: *const [save_size]u8) bool {
    const start = box_starts[0];
    const end = box_starts[5] + box_size;
    const expected = save[bank2_checksum_start];
    const calculated = bank_checksum(save, start, end);
    if (calculated != expected) return false;

    var i: usize = 0;
    while (i < 6): (i += 1) {
        const check_start = box_starts[i];
        const check_end_excl = box_starts[i] + box_size;
        const expected_ind = save[bank2_individual_checksum_start + i];
        const calculated_ind = bank_checksum(save, check_start, check_end_excl);
        if (calculated_ind != expected_ind) return false;
    }

    return true;
}


pub fn bank3_checksum_is_valid(save: *const [save_size]u8) bool {
    const start = box_starts[6];
    const end = box_starts[11] + box_size;
    const expected = save[bank3_checksum_start];
    const calculated = bank_checksum(save, start, end);
    if (calculated != expected) return false;

    var i: usize = 6;
    while (i < 12): (i += 1) {
        const check_start = box_starts[i];
        const check_end_excl = box_starts[i] + box_size;
        const expected_ind = save[bank3_individual_checksum_start + i - 6];
        const calculated_ind = bank_checksum(save, check_start, check_end_excl);
        if (calculated_ind != expected_ind) return false;
    }

    return true;
}

pub fn set_correct_checksums(save: *[save_size]u8) void {
    save[bank1_checksum_start] = bank_checksum(save, bank1_checksum_range_start, bank1_checksum_range_end_excl);
    save[bank2_checksum_start] = bank_checksum(save, box_starts[0], box_starts[5] + box_size);
    save[bank3_checksum_start] = bank_checksum(save, box_starts[6], box_starts[11] + box_size);

    var i: usize = 0;
    while (i < 6): (i += 1) {
        save[bank2_individual_checksum_start + i] = bank_checksum(save, box_starts[i], box_starts[i] + box_size);
    }

    i = 6;
    while (i < 12): (i += 1) {
        save[bank3_individual_checksum_start + i - 6] = bank_checksum(save, box_starts[i], box_starts[i] + box_size);
    }
}
