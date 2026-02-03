const std = @import("std");

const gen3_data = @import("save_datastructure.zig");
const moves_ns = @import("../general/moves.zig");
const encoding = @import("encoding.zig");

pub const gen3_species_data: *align (1) const[386]MonSpecies = std.mem.bytesAsValue([386]MonSpecies, @embedFile("species.dat"));

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

    pub fn init(ev_condition: gen3_data.EVConditionBlock) @This() {
        return .{
            .hp = ev_condition.hp_ev,
            .attack = ev_condition.attack_ev,
            .defense = ev_condition.defense_ev,
            .speed = ev_condition.speed_ev,
            .special_attack = ev_condition.special_attack_ev,
            .special_defense = ev_condition.special_defense_ev,
        };
    }
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

pub const StatTypes = enum {
    HP,
    ATTACK,
    DEFENSE,
    SPEED,
    SPECIAL_ATTACK,
    SPECIAL_DEFENSE
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

pub const MonSpecies = extern struct {
    base_hp: u8,
    base_attack: u8,
    base_defense: u8,
    base_speed: u8,
    base_special_attack: u8,
    base_special_defense: u8,
    type1: u8,
    type2: u8,
    catch_rate: u8,
    base_xp_yield: u8,
    effort_yield: u16,
    item1: u16,
    item2: u16,
    gender: u8,
    egg_cycles: u8,
    base_friendship: u8,
    levelup_type: u8,
    egg_group_1: u8,
    egg_group_2: u8,
    ability_1: u8,
    ability_2: u8,
    safari_zone_rate: u8,
    color_flip: u8,
    padding: u16
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
    ev: EV,
    contest_stats: ContestStats,
    pokerus: u8,
    met_location: u8,
    origins_info: Origins,
    iv_egg_ability: Ability,
    ribbons_obedience: Ribbons,

    fn fromStrippedMonData(stripped_mon_data: gen3_data.StrippedMonData, allocator: std.mem.Allocator) @This() {
        const growth_block = gen3_data.GrowthBlock.fromStrippedMonData(stripped_mon_data);
        const attack_block = gen3_data.AttackBlock.fromStrippedMonData(stripped_mon_data);
        const effort_block = gen3_data.EVConditionBlock.fromStrippedMonData(stripped_mon_data);
        const misc_block = gen3_data.MiscBlock.fromStrippedMonData(stripped_mon_data);

        return .{
            .personality_value = stripped_mon_data.personality_value,
            .ot_id = stripped_mon_data.ot_id,
            .nickname = encoding.gen3toUtf8(stripped_mon_data.nickname[0..], allocator) catch "",
            .language = @enumFromInt(stripped_mon_data.language),
            .misc_flags = MiscFlags.init(stripped_mon_data.misc_flags),
            .ot_name = encoding.gen3toUtf8(stripped_mon_data.ot_name[0..], allocator) catch "",
            .markings = stripped_mon_data.markings,
            .checksum = stripped_mon_data.checksum,
            .unknown0 = stripped_mon_data.unknown0,
            .dex_number = growth_block.dex_number,
            .item_held = growth_block.item_held,
            .experience = growth_block.experience,
            .pp_bonuses = .{growth_block.pp_bonuses.move1, growth_block.pp_bonuses.move2, growth_block.pp_bonuses.move3, growth_block.pp_bonuses.move4},
            .friendship = growth_block.friendship,
            .moves = attack_block.toMoveIds(),
            .pps = .{attack_block.pp1,attack_block.pp2,attack_block.pp3,attack_block.pp4},
            .ev = EV.init(effort_block),
            .contest_stats = ContestStats.init(effort_block),
            .pokerus = misc_block.pokerus,
            .met_location = misc_block.met_location,
            .origins_info = Origins.init(misc_block.origins),
            .iv_egg_ability = Ability.init(misc_block.ability),
            .ribbons_obedience = Ribbons.init(misc_block.ribbons),
        };
    }

    fn getNature(self: *const @This()) u8 {
        return @mod(self.personality_value, 25);
    }

    fn getNatureMultiplier(self: *const @This(), stat_type: StatTypes) f64 {
        const nature = self.getNature();
        const first_group = nature / 5;
        const second_group = @mod(nature, 5);
        if (first_group == second_group) {
            return 1.0;
        }
        if (stat_type == .ATTACK) {
            if (first_group == 0) return 1.1;
            if (second_group == 0) return 0.9;
        } else if (stat_type == .DEFENSE) {
            if (first_group == 1) return 1.1;
            if (second_group == 1) return 0.9;
        } else if (stat_type == .SPEED) {
            if (first_group == 2) return 1.1;
            if (second_group == 2) return 0.9;
        } else if (stat_type == .SPECIAL_ATTACK) {
            if (first_group == 3) return 1.1;
            if (second_group == 3) return 0.9;
        } else if (stat_type == .SPECIAL_DEFENSE) {
            if (first_group == 4) return 1.1;
            if (second_group == 4) return 0.9;
        }

        return 1.0;
    }
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

pub const XpGroup = enum(u8) {
    MEDIUM_FAST = 0,
    ERRATIC = 1,
    FLUCTUATING = 2,
    MEDIUM_SLOW = 3,
    FAST = 4,
    SLOW = 5
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

    pub fn fromMonData(mon_data: gen3_data.MonData) @This() {
        return .{
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
        };
    }

    pub fn fromMonBaseData(mon_base_data: MonBaseData) @This() {
        const species = gen3_species_data[mon_base_data.dex_number - 1];
        const level = level_from_dex_number_and_xp(mon_base_data.dex_number, mon_base_data.experience);
        const total_hp: u16 = calculate_max_hp(0, mon_base_data.iv_egg_ability.hp_iv, mon_base_data.ev.hp, level);

        return .{
            .status_condition = .{
                .bad_poison = false,
                .burn = false,
                .freeze = false,
                .paralysis = false,
                .poison = false,
                .sleep = false
            },
            .level = level,
            .mail_id = 0,
            .current_hp = total_hp,
            .total_hp = total_hp,
            .attack = calculate_other_stat(species.base_attack, mon_base_data.iv_egg_ability.attack_iv, mon_base_data.ev.attack, level, mon_base_data.getNatureMultiplier(.ATTACK)),
            .defense = calculate_other_stat(species.base_defense, mon_base_data.iv_egg_ability.defense_iv, mon_base_data.ev.defense, level, mon_base_data.getNatureMultiplier(.DEFENSE)),
            .speed = calculate_other_stat(species.base_speed, mon_base_data.iv_egg_ability.speed_iv, mon_base_data.ev.speed, level, mon_base_data.getNatureMultiplier(.SPEED)),
            .special_attack = calculate_other_stat(species.base_special_attack, mon_base_data.iv_egg_ability.special_attack_iv, mon_base_data.ev.special_attack, level, mon_base_data.getNatureMultiplier(.SPECIAL_ATTACK)),
            .special_defense = calculate_other_stat(species.base_special_defense, mon_base_data.iv_egg_ability.special_defense_iv, mon_base_data.ev.special_defense, level, mon_base_data.getNatureMultiplier(.SPECIAL_DEFENSE)),
        };
    }
};

fn level_from_dex_number_and_xp(dex_number: u16, xp: u32) u8 {
    const species = gen3_species_data[dex_number - 1];
    const xp_group: XpGroup = @enumFromInt(species.levelup_type);
    return switch (xp_group) {
        .ERRATIC => erratic_level(xp),
        .FAST => fast_level(xp),
        .FLUCTUATING => fluctuating_level(xp),
        .MEDIUM_FAST => medium_fast_level(xp),
        .MEDIUM_SLOW => medium_slow_level(xp),
        .SLOW => slow_level(xp)
    };
}

fn medium_fast_level(xp: u32) u8 {
    var i = 1;
    while (i <= 100): ( i += 1) {
        const required: usize = (i*i*i);
        if (required > xp) {
            return i - 1;
        }
    }
    return 100;
}

fn erratic_level(xp: u32) u8 {
    var i = 3;
    while (i < 50): (i += 1) {
        const required: usize = ((i*i*i)*(100 - i))/50;
        if (required > xp) {
            return i - 1;
        }
    }

    while (i < 68): (i += 1) {
        const required: usize = ((i*i*i)*(150 - i))/100;
        if (required > xp) {
            return i - 1;
        }
    }

    while (i < 98): (i += 1) {
        const required: usize = ((i*i*i)*((1911-10*i)/3))/500;
        if (required > xp) {
            return i - 1;
        }
    }

    while (i <= 100): (i += 1) {
        const required: usize = ((i*i*i)*(160 - i))/100;
        if (required > xp) {
            return i - 1;
        }
    }

    return 100;
}

fn fluctuating_level(xp: u32) u8 {
    var i = 3;
    while (i < 15): (i += 1) {
        const required: usize = ((i*i*i)*(24+((i + 1)/3)))/50;
        if (required > xp) {
            return i - 1;
        }
    }

    while (i < 36): (i += 1) {
        const required: usize = ((i*i*i)*(i + 14))/50;
        if (required > xp) {
            return i - 1;
        }
    }

    while (i <= 100): (i += 1) {
        const required: usize = ((i*i*i)*(32+((i + 0)/2)))/50;
        if (required > xp) {
            return i - 1;
        }
    }
    return 100;
}

fn medium_slow_level(xp: u32) u8 {
    if (xp < 9) return 1;
    if (xp < 57) return 2;
    var i = 3;
    while (i <= 100): ( i += 1) {
        const required: usize = ((i*i*i)*6)/5 - (i*i)*15 + 100 * i - 140;
        if (required > xp) {
            return i - 1;
        }
    }
    return 100;
}

fn fast_level(xp: u32) u8 {
    var i = 1;
    while (i <= 100): ( i += 1) {
        const required: usize = ((i*i*i)*4)/5;
        if (required > xp) {
            return i - 1;
        }
    }
    return 100;
}

fn slow_level(xp: u32) u8 {
    var i = 1;
    while (i <= 100): ( i += 1) {
        const required: usize = ((i*i*i)*5)/4;
        if (required > xp) {
            return i - 1;
        }
    }
    return 100;
}

fn calculate_max_hp(base_stat: u16, iv: u8, ev: u8, level: u8) u16 {
   return ((((ev/4) + iv + (2*base_stat)) * level) / 100) + level + 10;
}

fn calculate_other_stat(base_stat: u16, iv: u8, ev: u8, level: u8, nature: f64) u16 {
    const base = ((((ev/4) + iv + (2*base_stat)) * level) / 100) + 5;
    return @intFromFloat(base * nature);
}

pub const Mon = struct {
    base_data: MonBaseData,
    stats: Stats,

    pub fn fromStrippedMonData(stripped_mon_data: gen3_data.StrippedMonData) @This() {
        return fromMonData(gen3_data.MonData.fromStrippedMonData(stripped_mon_data));
    }

    pub fn fromMonData(mon_data: gen3_data.MonData, allocator: std.mem.Allocator) @This() {
        return .{
            .base_data = MonBaseData.fromStrippedMonData(mon_data.stripped_mon_data, allocator),
            .stats = Stats.fromMonData(mon_data)
        };
    }
};