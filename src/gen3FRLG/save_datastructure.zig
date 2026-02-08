const std = @import("std");
const moves_ns = @import("../general/moves.zig");
const gen3 = @import("mon.zig");
const encoding = @import("encoding.zig");

const copyForwards = std.mem.copyForwards;
const asBytes = std.mem.asBytes;

pub const save_size = 1 << 17;

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
pub const party_mon_details_size = 604;
pub const party_size = 1528;

pub const stripped_mon_size = 80;
pub const full_mon_size = 100;
pub const mon_subsection_size = 12;

pub const number_of_boxes = 14;
pub const mon_per_box = 30;
pub const total_box_mon = number_of_boxes * mon_per_box;

pub const box_size = stripped_mon_size * mon_per_box;

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

fn getBlockNumber(personality_value: u32, letter: u8) u8 {
    const block_order_index: u8 = @intCast(@mod(personality_value, 24));
    return @intCast(std.mem.indexOfScalar(u8, orderings[block_order_index], letter).?);
}

fn encrypt(personality_value: u32, ot_id: u32, data: [12]u8) [12]u8 {
    const encryption_key = personality_value ^ ot_id;
    const data_u32: [3]u32 = @bitCast(data);
    var encrypted_u32: [3]u32 = undefined;
    var i: usize = 0;
    while (i < data_u32.len): (i += 1) {
        encrypted_u32[i] = data_u32[i] ^ encryption_key;
    }
    return @bitCast(encrypted_u32);
}

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


pub const GrowthBlock = packed struct {
    dex_number: u16,
    item_held: u16,
    experience: u32,
    pp_bonuses: PPBonuses,
    friendship: u8,
    padding: u16,

    pub fn fromStrippedMonData(stripped_mon_data: StrippedMonData) @This() {
        const decrypted: [12]u8 = getDecryptedBlock(stripped_mon_data, 'G');
        return .{
            .dex_number = @bitCast(decrypted[0..2].*),
            .item_held = @bitCast(decrypted[2..4].*),
            .experience = @bitCast(decrypted[4..8].*),
            .pp_bonuses = @bitCast(decrypted[8]),
            .friendship = decrypted[9],
            .padding = @bitCast(decrypted[10..12].*)
        };
    }

    pub fn toBytes(self: *const @This()) [12]u8 {
        return @bitCast(self.*);
    }
};

pub const AttackBlock = packed struct {
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

    pub fn toBytes(self: *const @This()) [12]u8 {
        return @bitCast(self.*);
    }
};

pub const EVConditionBlock = packed struct {
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

    pub fn toBytes(self: *const @This()) [12]u8 {
        return @bitCast(self.*);
    }
};

pub const Origins = packed struct {
    level_met: u7,
    origin_game: u4,
    pokeball_type: u4,
    trainer_is_female: bool,

    fn fromMon(mon_origins: gen3.Origins) @This() {
        return .{
            .level_met = mon_origins.level_met,
            .origin_game = mon_origins.origin_game,
            .pokeball_type = mon_origins.pokeball_type,
            .trainer_is_female = mon_origins.trainer_is_female
        };
    }
};

pub const Ability = packed struct {
    hp_iv: u5,
    attack_iv: u5,
    defense_iv: u5,
    speed_iv: u5,
    special_attack_iv: u5,
    special_defense_iv: u5,
    egg: bool,
    ability: u1,

    fn fromMon(mon_ability: gen3.Ability) @This() {
        return .{
            .hp_iv = mon_ability.hp_iv,
            .attack_iv = mon_ability.attack_iv,
            .defense_iv = mon_ability.defense_iv,
            .speed_iv = mon_ability.speed_iv,
            .special_attack_iv = mon_ability.special_attack_iv,
            .special_defense_iv = mon_ability.special_defense_iv,
            .egg = mon_ability.egg,
            .ability = mon_ability.ability
        };
    }
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
    obedience: bool,

    fn fromMon(mon_ribbons: gen3.Ribbons) @This() {
        return .{
            .cool = mon_ribbons.cool,
            .beauty = mon_ribbons.beauty,
            .cute = mon_ribbons.cute,
            .smart = mon_ribbons.smart,
            .tough = mon_ribbons.tough,
            .champion = mon_ribbons.champion,
            .winning = mon_ribbons.winning,
            .victory = mon_ribbons.victory,
            .artist = mon_ribbons.artist,
            .effort = mon_ribbons.effort,
            .battle_champion = mon_ribbons.battle_champion,
            .regional_champion = mon_ribbons.regional_champion,
            .national_champion = mon_ribbons.national,
            .country = mon_ribbons.country,
            .national = mon_ribbons.national,
            .earth = mon_ribbons.earth,
            .world = mon_ribbons.world,
            .padding0 = 0,
            .obedience = mon_ribbons.obedience
        };
    }
};

pub const MiscBlock = packed struct {
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

    pub fn toBytes(self: *const @This()) [12]u8 {
        return @bitCast(self.*);
    }
};

pub const MiscFlags = packed struct {
    is_bad_egg: bool,
    has_species: bool,
    use_egg_name: bool,
    block_box_rs: bool,
    padding0: u4,

    fn fromMonFlags(mon_misc_flags: gen3.MiscFlags) @This() {
        return .{
            .is_bad_egg = mon_misc_flags.is_bad_egg,
            .has_species = mon_misc_flags.has_species,
            .use_egg_name = mon_misc_flags.use_egg_name,
            .block_box_rs = mon_misc_flags.block_box_rs,
            .padding0 = 0
        };
    }
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

    pub fn fromMon(mon: gen3.Mon) @This() {
        var ot_name: [7]u8 = undefined;
        std.mem.copyForwards(u8, &ot_name, &encoding.utf8ToGen3(mon.base_data.ot_name));

        const misc_block: MiscBlock = .{
            .ability = Ability.fromMon(mon.base_data.iv_egg_ability),
            .met_location = mon.base_data.met_location,
            .origins = Origins.fromMon(mon.base_data.origins_info),
            .pokerus = mon.base_data.pokerus,
            .ribbons = Ribbons.fromMon(mon.base_data.ribbons_obedience)
        };

        const attack_block: AttackBlock = .{
            .move1 = mon.base_data.moves[0].?.id,
            .move2 = mon.base_data.moves[1].?.id,
            .move3 = mon.base_data.moves[2].?.id,
            .move4 = mon.base_data.moves[3].?.id,
            .pp1 = mon.base_data.pps[0],
            .pp2 = mon.base_data.pps[1],
            .pp3 = mon.base_data.pps[2],
            .pp4 = mon.base_data.pps[3]
        };

        const ev_block: EVConditionBlock = .{
            .attack_ev = mon.base_data.ev.attack,
            .defense_ev = mon.base_data.ev.defense,
            .speed_ev = mon.base_data.ev.speed,
            .special_attack_ev = mon.base_data.ev.special_attack,
            .special_defense_ev = mon.base_data.ev.special_defense,
            .hp_ev = mon.base_data.ev.hp,
            .beauty = mon.base_data.contest_stats.beauty,
            .coolness = mon.base_data.contest_stats.coolness,
            .cuteness = mon.base_data.contest_stats.cuteness,
            .feel = mon.base_data.contest_stats.feel,
            .smartness = mon.base_data.contest_stats.smartness,
            .toughness = mon.base_data.contest_stats.toughness
        };

        const growth_block: GrowthBlock = .{
            .dex_number = mon.base_data.dex_number,
            .experience = mon.base_data.experience,
            .friendship = mon.base_data.friendship,
            .item_held = mon.base_data.friendship,
            .padding = 0,
            .pp_bonuses = .{
                .move1 = mon.base_data.pp_bonuses[0],
                .move2 = mon.base_data.pp_bonuses[1],
                .move3 = mon.base_data.pp_bonuses[2],
                .move4 = mon.base_data.pp_bonuses[3]
            }
        };

        const growth_block_bytes = growth_block.toBytes();
        const attack_block_bytes = attack_block.toBytes();
        const misc_block_bytes = misc_block.toBytes();
        const ev_block_bytes = ev_block.toBytes();

        const checksum = calculate_checksum_for_byte_blocks(.{growth_block_bytes, attack_block_bytes, misc_block_bytes, ev_block_bytes});

        const encrypted_growth_block = encrypt(mon.base_data.personality_value, mon.base_data.ot_id, growth_block_bytes);
        const encrypted_attack_block = encrypt(mon.base_data.personality_value, mon.base_data.ot_id, attack_block_bytes);
        const encrypted_misc_block = encrypt(mon.base_data.personality_value, mon.base_data.ot_id, misc_block_bytes);
        const encrypted_ev_block = encrypt(mon.base_data.personality_value, mon.base_data.ot_id, ev_block_bytes);

        var data: [48]u8 = undefined;

        const growth_block_start = getBlockNumber(mon.base_data.personality_value, 'G') * 12;
        const attack_block_start = getBlockNumber(mon.base_data.personality_value, 'A') * 12;
        const misc_block_start = getBlockNumber(mon.base_data.personality_value, 'M') * 12;
        const ev_block_start = getBlockNumber(mon.base_data.personality_value, 'E') * 12;

        std.mem.copyForwards(u8, data[growth_block_start..growth_block_start + 12], &encrypted_growth_block);
        std.mem.copyForwards(u8, data[attack_block_start..attack_block_start + 12], &encrypted_attack_block);
        std.mem.copyForwards(u8, data[misc_block_start..misc_block_start + 12], &encrypted_misc_block);
        std.mem.copyForwards(u8, data[ev_block_start..ev_block_start + 12], &encrypted_ev_block);

        return .{
            .personality_value = mon.base_data.personality_value,
            .ot_id = mon.base_data.ot_id,
            .nickname = encoding.utf8ToGen3(mon.base_data.nickname),
            .language = @intFromEnum(mon.base_data.language),
            .misc_flags = MiscFlags.fromMonFlags(mon.base_data.misc_flags),
            .ot_name = ot_name,
            .markings = mon.base_data.markings,
            .checksum = checksum,
            .unknown0 = 0,
            .data = data
        };
    }

    fn getBlockOrderIndex(self: *const@This()) u8 {
        return @intCast(@mod(self.personality_value, 24));
    }

    pub fn calculate_checksum(self: *const@This()) u16 {
        var result: u16 = 0;
        const block1: [6]u16 = @bitCast(getDecryptedBlock(self.*, 'G'));
        const block2: [6]u16 = @bitCast(getDecryptedBlock(self.*, 'A'));
        const block3: [6]u16 = @bitCast(getDecryptedBlock(self.*, 'M'));
        const block4: [6]u16 = @bitCast(getDecryptedBlock(self.*, 'E'));
        const blocks: [4][6]u16 = .{block1, block2, block3, block4};
        for (blocks) |block| {
            for (block) |word| {
                result +%= word;
            }
        }

        return result;
    }

    fn calculate_checksum_for_byte_blocks(byte_blocks: [4][12]u8) u16 {
        var result: u16 = 0;
        const block1: [6]u16 = @bitCast(byte_blocks[0]);
        const block2: [6]u16 = @bitCast(byte_blocks[1]);
        const block3: [6]u16 = @bitCast(byte_blocks[2]);
        const block4: [6]u16 = @bitCast(byte_blocks[3]);
        const blocks: [4][6]u16 = .{block1, block2, block3, block4};
        for (blocks) |block| {
            for (block) |word| {
                result +%= word;
            }
        }

        return result;
    }

    fn toBytes(self: *const @This()) [stripped_mon_size]u8 {
        var result: [stripped_mon_size]u8 = undefined;
        copyForwards(u8, result[0..4], &asBytes(self.personality_value));
        copyForwards(u8, result[4..8], asBytes(self.ot_id));
        copyForwards(u8, result[8..18], &self.nickname);
        result[18] = self.language;
        result[19] = @bitCast(self.misc_flags);
        copyForwards(u8, result[20..27], &self.ot_name);
        result[27] = self.markings;
        copyForwards(u8, result[28..30], &asBytes(self.checksum));
        copyForwards(u8, result[30..32], &asBytes(self.unknown0));
        copyForwards(u8, result[32..80], &self.data);
        return result;
    }

};

pub const StatusCondition = packed struct {
    sleep: u3,
    poison: bool,
    burn: bool,
    freeze: bool,
    paralysis: bool,
    bad_poison: bool,
    padding0: u24,

    fn allOk() @This() {
        return .{
            .sleep = 0,
            .poison = false,
            .burn = false,
            .freeze = false,
            .paralysis = false,
            .bad_poison = false,
            .padding= 0
        };
    }
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

    fn toBytes(self: *const @This()) [full_mon_size]u8 {
        var result: [full_mon_size]u8 = undefined;
        copyForwards(u8, result[0..80], self.stripped_mon_data.toBytes()[0..]);
        copyForwards(u8, result[80..84], asBytes(self.status_condition));
        result[84] = self.level;
        result[85] = self.mail_id;
        copyForwards(u8, result[86..88], &asBytes(self.current_hp));
        copyForwards(u8, result[88..90], &asBytes(self.total_hp));
        copyForwards(u8, result[90..92], &asBytes(self.attack));
        copyForwards(u8, result[92..94], &asBytes(self.defense));
        copyForwards(u8, result[94..96], &asBytes(self.speed));
        copyForwards(u8, result[96..98], &asBytes(self.special_attack));
        copyForwards(u8, result[98..100], &.asBytes(self.special_defense));
        return result;
    }

    pub fn fromMon(mon: gen3.Mon) @This() {
        return .{
            .stripped_mon_data = StrippedMonData.fromMon(mon),
            .status_condition = StatusCondition.allOk(),
            .level = mon.stats.level,
            .mail_id = mon.stats.mail_id,
            .current_hp = mon.stats.current_hp,
            .total_hp = mon.stats.total_hp,
            .attack = mon.stats.attack,
            .defense = mon.stats.defense,
            .speed = mon.stats.speed,
            .special_attack = mon.stats.special_attack,
            .special_defense = mon.stats.special_defense
        };
    }

};

pub const FullPartyData = struct {
    number_of_mon: u8,
    mons: [6]MonData,

    pub fn init(bytes: []const u8) @This() {
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

    pub fn toBytes(self: *const @This()) [party_mon_details_size]u8 {
        _ = self;
    }
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

pub fn data_is_gen3_save(bytes: []const u8) bool {
    if (bytes.len != 1 << 17) return false;
    const magic_bytes = bytes[signature_offset..signature_offset + 4];
    return std.mem.eql(u8, &[4]u8{0x25, 0x20, 0x01, 0x08}, magic_bytes);
}

pub fn getBoxBytes(bytes: []const u8) [boxes_total_size]u8 {
    var result: [boxes_total_size]u8 = undefined;

    var i: usize = first_box_section_id;
    var moved: usize = 0;
    while (i <= last_fullsize_box_section_id ): ( i += 1 ) {
        const section_start = getSectionStart(bytes, @intCast(i));
        std.mem.copyForwards(u8, result[moved..moved + box_section_size], bytes[section_start..section_start + box_section_size]);
        moved += box_section_size;
    }
    const last_section_start = getSectionStart(bytes, last_box_section_id);
    std.mem.copyForwards(u8, result[moved..moved + last_box_section_size], bytes[last_section_start..last_section_start + last_box_section_size]);

    return result;
}

pub const FullBoxData = struct {
    number_of_mons: u8,
    mons: [mon_per_box]StrippedMonData,

    pub fn init(bytes: *const[box_size]u8) @This() {
        var number_of_mon: u8 = 0;
        var mons: [mon_per_box]StrippedMonData = undefined;

        var i: usize = 0;
        while (i < mon_per_box): (i += 1) {
            const start = i * stripped_mon_size;
            const end = start + stripped_mon_size;
            const mon_bytes = bytes[start..end][0..80];
            var j: usize = 0;
            var active = false;
            while (j < mon_bytes.len and !active): (j += 1) {
                if (mon_bytes[j] != 0) {
                    active = true;
                }
            }
            if (active) {
                const mon = StrippedMonData.fromBytes(bytes[start..end][0..80].*);
                mons[number_of_mon] = mon;
                number_of_mon += 1;
            }
        }
        return .{
            .number_of_mons = number_of_mon,
            .mons = mons
        };
    }
};

