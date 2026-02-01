const std = @import("std");
const moves_ns = @import("../general/moves.zig");

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
pub const party_mons_offset = 0x0038;
pub const party_size = 1528;

pub const stripped_mon_size = 80;
pub const full_mon_size = 100;
pub const mon_subsection_size = 12;

pub const orderings: [24][]const u8 = .{
    "GAEM",
    "GAME",
    "GEAM",
    "GEMA",
    "GMAE",
    "GMEA",
    "AGEM",
    "AGME",
    "AEGM",
    "AEMG",
    "AMGE",
    "AMEG",
    "EGAM",
    "EGMA",
    "EAGM",
    "EAMG",
    "EMGA",
    "EMAG",
    "MGAE",
    "MGEA",
    "MAGE",
    "MAEG",
    "MEGA",
    "MEAG",
};

fn getDecryptedBlock(stripped_mon_data: StrippedMonData, letter: u8) [12]u8 {
    const encryption_key = stripped_mon_data.personality_value ^ stripped_mon_data.ot_id;
    const block_order_index = stripped_mon_data.getBlockOrderIndex();
    const block_number = std.mem.indexOfScalar(u8, orderings[block_order_index], letter).?;
    const encrypted_data = stripped_mon_data.data[block_number * mon_subsection_size..(block_number * mon_subsection_size) + mon_subsection_size][0..mon_subsection_size];
    const encrypted_u32: [3]u32 = @bitCast(encrypted_data.*);
    var decrypted_u32: [3]u32 = undefined;
    var i: usize = 0;
    while (i < encrypted_u32.len): ( i += 1) {
        decrypted_u32[i] = encrypted_u32[i] ^ encryption_key;
    }

    return @bitCast(decrypted_u32);
}

pub const PPBonuses = packed struct {
    move1: u2,
    move2: u2,
    move3: u2,
    move4: u2
};


pub const GrowthBlock = struct {
    dex_number: u16,
    item_held: u16,
    experience: u32,
    pp_bonuses: PPBonuses,
    friendship: u8,

    pub fn fromStrippedMonData(stripped_mon_data: StrippedMonData) @This() {
        const decrypted: [12]u8 = getDecryptedBlock(stripped_mon_data, 'G');

        return .{
            .dex_number = @bitCast(decrypted[0..2].*),
            .item_held = @bitCast(decrypted[2..4].*),
            .experience = @bitCast(decrypted[4..8].*),
            .pp_bonuses = @bitCast(decrypted[8]),
            .friendship = decrypted[9]
        };
    }
};

pub const AttackBlock = struct {
    move1: u16,
    move2: u16,
    move3: u16,
    move4: u16,
    pp1: u8,
    pp2: u8,
    pp3: u8,
    pp4: u8,

    pub fn fromStrippedMonData(stripped_mon_data: StrippedMonData) @This() {
        const decrypted: [12]u8 = getDecryptedBlock(stripped_mon_data, 'A');
        return .{
            .move1 = @bitCast(decrypted[0..2].*),
            .move2 = @bitCast(decrypted[2..4].*),
            .move3 = @bitCast(decrypted[4..6].*),
            .move4 = @bitCast(decrypted[6..8].*),
            .pp1 = decrypted[8],
            .pp2 = decrypted[9],
            .pp3 = decrypted[10],
            .pp4 = decrypted[11],
        };
    }

    pub fn toMoveIds(self: *const @This()) [4]?*const moves_ns.Move {
        var result: [4]?*const moves_ns.Move =.{null} ** 4;
        if (self.move1 != 0) result[0] = &moves_ns.moves[self.move1 - 1];
        if (self.move2 != 0) result[1] = &moves_ns.moves[self.move2 - 1];
        if (self.move3 != 0) result[2] = &moves_ns.moves[self.move3 - 1];
        if (self.move4 != 0) result[3] = &moves_ns.moves[self.move4 - 1];
        return result;
    }
};

pub const EVConditionBlock = struct {
    hp_ev: u8,
    attack_ev: u8,
    defense_ev: u8,
    speed_ev: u8,
    special_attack_ev: u8,
    special_defense_ev: u8,
    coolness: u8,
    beauty: u8,
    cuteness: u8,
    smartness: u8,
    toughness: u8,
    feel: u8,

    pub fn fromStrippedMonData(stripped_mon_data: StrippedMonData) @This() {
        const decrypted: [12]u8 = getDecryptedBlock(stripped_mon_data, 'E');
        return .{
            .hp_ev = decrypted[0],
            .attack_ev = decrypted[1],
            .defense_ev = decrypted[2],
            .speed_ev = decrypted[3],
            .special_attack_ev = decrypted[4],
            .special_defense_ev = decrypted[5],
            .coolness = decrypted[6],
            .beauty = decrypted[7],
            .cuteness = decrypted[8],
            .smartness = decrypted[9],
            .toughness = decrypted[10],
            .feel = decrypted[11]
        };

    }
};

pub const Origins = packed struct {
    level_met: u7,
    origin_game: u4,
    pokeball_type: u4,
    trainer_is_female: bool
};

pub const Ability = packed struct {
    hp_iv: u5,
    attack_iv: u5,
    defense_iv: u5,
    speed_iv: u5,
    special_attack_iv: u5,
    special_defense_iv: u5,
    egg: bool,
    ability: u1
};

pub const Ribbons = packed struct {
    cool: u3,
    beauty: u3,
    cute: u3,
    smart: u3,
    tough: u3,
    champion: bool,
    winning: bool,
    victory: bool,
    artist: bool,
    effort: bool,
    battle_champion: bool,
    regional_champion: bool,
    national_champion: bool,
    country: bool,
    national: bool,
    earth: bool,
    world: bool,
    padding0: u4,
    obedience: bool
};

pub const MiscBlock = struct {
    pokerus: u8,
    met_location: u8,
    origins: Origins,
    ability: Ability,
    ribbons: Ribbons,

    pub fn fromStrippedMonData(stripped_mon_data: StrippedMonData) @This() {
        const decrypted: [12]u8 = getDecryptedBlock(stripped_mon_data, 'M');
        return .{
            .pokerus = decrypted[0],
            .met_location = decrypted[1],
            .origins = @bitCast(decrypted[2..4].*),
            .ability = @bitCast(decrypted[4..8].*),
            .ribbons = @bitCast(decrypted[8..12].*)
        };
    }
};

pub const MiscFlags = packed struct {
    is_bad_egg: bool,
    has_species: bool,
    use_egg_name: bool,
    block_box_rs: bool,
    padding0: u4
};

pub const StrippedMonData = struct {
    personality_value: u32,
    ot_id: u32,
    nickname: [10]u8,
    language: u8,
    misc_flags: MiscFlags,
    ot_name: [7]u8,
    markings: u8,
    checksum: u16,
    unknown0: u16,
    data: [48]u8,

    fn fromBytes(bytes: [stripped_mon_size]u8) @This() {
        return .{
            .personality_value = @bitCast(bytes[0..4].*),
            .ot_id = @bitCast(bytes[4..8].*),
            .nickname = bytes[8..18].*,
            .language = bytes[18],
            .misc_flags = @bitCast(bytes[19]),
            .ot_name = bytes[20..27].*,
            .markings = bytes[27],
            .checksum = @bitCast(bytes[28..30].*),
            .unknown0 = @bitCast(bytes[30..32].*),
            .data = bytes[32..80].*
        };
    }

    fn getBlockOrderIndex(self: *const@This()) u8 {
        return @intCast(@mod(self.personality_value, 24));
    }

};

pub const StatusCondition = packed struct {
    sleep: u3,
    poison: bool,
    burn: bool,
    freeze: bool,
    paralysis: bool,
    bad_poison: bool,
    padding0: u24
};

pub const MonData = struct {
    stripped_mon_data: StrippedMonData,
    status_condition: StatusCondition,
    level: u8,
    mail_id: u8,
    current_hp: u16,
    total_hp: u16,
    attack: u16,
    defense: u16,
    speed: u16,
    special_attack: u16,
    special_defense: u16,

    fn fromBytes(bytes: [full_mon_size]u8) @This() {
        return .{
            .stripped_mon_data = StrippedMonData.fromBytes(bytes[0..80].*),
            .status_condition = @bitCast(bytes[80..84].*),
            .level = bytes[84],
            .mail_id = bytes[85],
            .current_hp = @bitCast(bytes[86..88].*),
            .total_hp = @bitCast(bytes[88..90].*),
            .attack = @bitCast(bytes[90..92].*),
            .defense = @bitCast(bytes[92..94].*),
            .speed = @bitCast(bytes[94..96].*),
            .special_attack = @bitCast(bytes[96..98].*),
            .special_defense = @bitCast(bytes[98..100].*)
        };
    }

    pub fn fromStrippedMonData(stripped_mon_data: StrippedMonData) @This() {
        return .{
            .stripped_mon_data = stripped_mon_data,
            .status_condition = 0,
            .level = 0,
            .mail_id = 0,
            .current_hp = 0,
            .total_hp = 0,
            .attack = 0,
            .defense = 0,
            .speed = 0,
            .special_attack = 0,
            .special_defense = 0
        };
    }

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

pub fn getFullPartyData(bytes: []const u8) FullPartyData {
    const party_section_start = getSectionStart(bytes, party_section_id);
    const mon_start = party_section_start + party_mons_offset;
    const mon_bytes = bytes[mon_start..mon_start + 600];
    return .{
        .number_of_mon = bytes[party_section_start + party_offset],
        .mons =
            .{MonData.fromBytes(mon_bytes[0..100].*), MonData.fromBytes(mon_bytes[100..200].*),
              MonData.fromBytes(mon_bytes[200..300].*), MonData.fromBytes(mon_bytes[300..400].*),
              MonData.fromBytes(mon_bytes[400..500].*), MonData.fromBytes(mon_bytes[500..600].*)},
    };

}

