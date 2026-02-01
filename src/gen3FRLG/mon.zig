const std = @import("std");

const gen3_data = @import("save_datastructure.zig");
const moves_ns = @import("../general/moves.zig");
const encoding = @import("encoding.zig");

pub const ContestStats = struct {
    coolness: u8,
    beauty: u8,
    cuteness: u8,
    smartness: u8,
    toughness: u8,
    feel: u8,

    pub fn init(conditions: gen3_data.EVConditionBlock) @This() {
        return .{
            .coolness = conditions.coolness,
            .beauty = conditions.beauty,
            .cuteness = conditions.cuteness,
            .smartness = conditions.smartness,
            .toughness = conditions.toughness,
            .feel = conditions.feel
        };
    }
};

pub const EV = struct {
    hp: u8,
    attack: u8,
    defense: u8,
    speed: u8,
    special_attack: u8,
    special_defense: u8,
};

pub const IV = struct {
    hp: u8,
    attack: u8,
    defense: u8,
    speed: u8,
    special_attack: u8,
    special_defense: u8,
};

pub const Language = enum(u8) {
    JAPANESE = 1,
    ENGLISH = 2,
    FRENCH = 3,
    ITALIAN = 4,
    GERMAN = 5,
    UNUSED = 6,
    SPANISH = 7
};

pub const MiscFlags = struct {
    is_bad_egg: bool,
    has_species: bool,
    use_egg_name: bool,
    block_box_rs: bool,

    pub fn init(misc_flags: gen3_data.MiscFlags) @This() {
        return .{
            .is_bad_egg = misc_flags.is_bad_egg,
            .has_species = misc_flags.has_species,
            .use_egg_name = misc_flags.use_egg_name,
            .block_box_rs = misc_flags.block_box_rs
        };
    }
};

pub const MonBaseData = struct {
    personality_value: u32,
    ot_id: u32,
    nickname: []u8,
    language: Language,
    misc_flags: MiscFlags,
    ot_name: []u8,
    markings: u8,
    checksum: u16,
    unknown0: u16,
    dex_number: u16,
    item_held: u16,
    experience: u32,
    pp_bonuses: [4]u2,
    friendship: u8,
    moves: [4]?*const moves_ns.Move,
    pps: [4]u8,
    contest_stats: ContestStats,
    pokerus: u8,
    met_location: u8,
    origins_info: Origins,
    iv_egg_ability: Ability,
    ribbons_obedience: Ribbons,
};

pub const StatusCondition = struct {
    sleep: u3,
    poison: bool,
    burn: bool,
    freeze: bool,
    paralysis: bool,
    bad_poison: bool,

    pub fn init(status_condition: gen3_data.StatusCondition) @This() {
        return .{
            .sleep = status_condition.sleep,
            .poison = status_condition.poison,
            .burn = status_condition.burn,
            .freeze = status_condition.freeze,
            .paralysis = status_condition.paralysis,
            .bad_poison = status_condition.bad_poison
        };
    }
};

pub const Ability = struct {
    hp_iv: u5,
    attack_iv: u5,
    defense_iv: u5,
    speed_iv: u5,
    special_attack_iv: u5,
    special_defense_iv: u5,
    egg: bool,
    ability: u1,

    pub fn init(ability: gen3_data.Ability) @This() {
        return .{
            .hp_iv = ability.hp_iv,
            .attack_iv = ability.attack_iv,
            .defense_iv = ability.defense_iv,
            .speed_iv = ability.speed_iv,
            .special_attack_iv = ability.special_attack_iv,
            .special_defense_iv = ability.special_defense_iv,
            .egg = ability.egg,
            .ability = ability.ability
        };
    }
};

pub const Origins = packed struct {
    level_met: u7,
    origin_game: u4,
    pokeball_type: u4,
    trainer_is_female: bool,

    pub fn init(origins: gen3_data.Origins) @This() {
        return Origins{
            .level_met = origins.level_met,
            .origin_game = origins.origin_game,
            .pokeball_type = origins.pokeball_type,
            .trainer_is_female = origins.trainer_is_female
        };
    }
};

pub const Ribbons = struct {
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
    obedience: bool,

    pub fn init(ribbons: gen3_data.Ribbons) @This() {
        return .{
            .cool = ribbons.cool,
            .beauty= ribbons.beauty,
            .cute= ribbons.cute,
            .smart= ribbons.smart,
            .tough= ribbons.tough,
            .champion= ribbons.champion,
            .winning= ribbons.winning,
            .victory= ribbons.victory,
            .artist= ribbons.artist,
            .effort= ribbons.effort,
            .battle_champion= ribbons.battle_champion,
            .regional_champion= ribbons.regional_champion,
            .national_champion= ribbons.national_champion,
            .country= ribbons.country,
            .national= ribbons.national,
            .earth= ribbons.earth,
            .world= ribbons.world,
            .obedience= ribbons.obedience,
        };
    }
};

pub const Stats = struct {
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
};

pub const Mon = struct {
    base_data: MonBaseData,
    stats: Stats,

    pub fn fromStrippedMonData(stripped_mon_data: gen3_data.StrippedMonData) @This() {
        return fromMonData(gen3_data.MonData.fromStrippedMonData(stripped_mon_data));
    }

    pub fn fromMonData(mon_data: gen3_data.MonData, allocator: std.mem.Allocator) @This() {
        const growth_block = gen3_data.GrowthBlock.fromStrippedMonData(mon_data.stripped_mon_data);
        const attack_block = gen3_data.AttackBlock.fromStrippedMonData(mon_data.stripped_mon_data);
        const effort_block = gen3_data.EVConditionBlock.fromStrippedMonData(mon_data.stripped_mon_data);
        const misc_block = gen3_data.MiscBlock.fromStrippedMonData(mon_data.stripped_mon_data);

        return .{
            .base_data = .{
                .personality_value = mon_data.stripped_mon_data.personality_value,
                .ot_id = mon_data.stripped_mon_data.ot_id,
                .nickname = encoding.gen3toUtf8(mon_data.stripped_mon_data.nickname[0..], allocator) catch "",
                .language = @enumFromInt(mon_data.stripped_mon_data.language),
                .misc_flags = MiscFlags.init(mon_data.stripped_mon_data.misc_flags),
                .ot_name = encoding.gen3toUtf8(mon_data.stripped_mon_data.ot_name[0..], allocator) catch "",
                .markings = mon_data.stripped_mon_data.markings,
                .checksum = mon_data.stripped_mon_data.checksum,
                .unknown0 = mon_data.stripped_mon_data.unknown0,
                .dex_number = growth_block.dex_number,
                .item_held = growth_block.item_held,
                .experience = growth_block.experience,
                .pp_bonuses = .{growth_block.pp_bonuses.move1, growth_block.pp_bonuses.move2, growth_block.pp_bonuses.move3, growth_block.pp_bonuses.move4},
                .friendship = growth_block.friendship,
                .moves = attack_block.toMoveIds(),
                .pps = .{attack_block.pp1,attack_block.pp2,attack_block.pp3,attack_block.pp4},
                .contest_stats = ContestStats.init(effort_block),
                .pokerus = misc_block.pokerus,
                .met_location = misc_block.met_location,
                .origins_info = Origins.init(misc_block.origins),
                .iv_egg_ability = Ability.init(misc_block.ability),
                .ribbons_obedience = Ribbons.init(misc_block.ribbons),
            },
            .stats = .{
                .status_condition = StatusCondition.init(mon_data.status_condition),
                .level = mon_data.level,
                .mail_id = mon_data.level,
                .current_hp = mon_data.current_hp,
                .total_hp = mon_data.total_hp,
                .attack = mon_data.attack,
                .defense = mon_data.defense,
                .speed = mon_data.speed,
                .special_attack = mon_data.special_attack,
                .special_defense = mon_data.defense,
            }
        };
    }
};