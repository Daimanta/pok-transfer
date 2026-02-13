const std = @import("std");

const gen3_data = @import("save_datastructure.zig");
const moves_ns = @import("../general/moves.zig");
const encoding = @import("encoding.zig");
const interface = @import("../general/interface.zig");
const versions = @import("../general/versions.zig");
const pok_transfer = @import("../root.zig");

pub const save_size = gen3_data.save_size;
pub const number_of_boxes = 14;
pub const box_size = 30;
pub const party_size = 6;

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

    fn no_stats() @This() {
        return .{
            .coolness = 0,
            .beauty = 0,
            .cuteness = 0,
            .smartness = 0,
            .toughness = 0,
            .feel = 0
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

    fn fromGen1(ev: @import("../gen1/mon.zig").EV) @This() {
        var new_hp_ev = ev.hp / 256;
        var new_attack_ev = ev.attack / 256;
        var new_defense_ev = ev.defense / 256;
        var new_speed_ev = ev.speed / 256;
        var new_special_attack_ev = ev.special / 256;
        var new_special_defense_ev = ev.special / 256;

        const ev_sum = new_hp_ev + new_attack_ev + new_defense_ev + new_speed_ev + new_special_attack_ev + new_special_defense_ev;
        if (ev_sum > 510) {
            const factor: f64 = 510.0 / @as(f64, @floatFromInt(ev_sum));
            new_hp_ev = factor_ev(new_hp_ev, factor);
            new_attack_ev = factor_ev(new_attack_ev, factor);
            new_defense_ev = factor_ev(new_defense_ev, factor);
            new_speed_ev = factor_ev(new_speed_ev, factor);
            new_special_attack_ev = factor_ev(new_special_attack_ev, factor);
            new_special_defense_ev = factor_ev(new_special_defense_ev, factor);
        }
        
        return .{
            .hp = @intCast(new_hp_ev),
            .attack = @intCast(new_attack_ev),
            .defense = @intCast(new_defense_ev),
            .speed = @intCast(new_speed_ev),
            .special_attack = @intCast(new_special_attack_ev),
            .special_defense = @intCast(new_special_defense_ev),
        };
        
    }
    
    fn fromGen2(ev: @import("../gen2GS/mon.zig").EV) @This() {
        var new_hp_ev = ev.hp / 256;
        var new_attack_ev = ev.attack / 256;
        var new_defense_ev = ev.defense / 256;
        var new_speed_ev = ev.speed / 256;
        var new_special_attack_ev = ev.special / 256;
        var new_special_defense_ev = ev.special / 256;

        const ev_sum = new_hp_ev + new_attack_ev + new_defense_ev + new_speed_ev + new_special_attack_ev + new_special_defense_ev;
        if (ev_sum > 510) {
            const factor: f64 = 510.0 / @as(f64, @floatFromInt(ev_sum));
            new_hp_ev = factor_ev(new_hp_ev, factor);
            new_attack_ev = factor_ev(new_attack_ev, factor);
            new_defense_ev = factor_ev(new_defense_ev, factor);
            new_speed_ev = factor_ev(new_speed_ev, factor);
            new_special_attack_ev = factor_ev(new_special_attack_ev, factor);
            new_special_defense_ev = factor_ev(new_special_defense_ev, factor);
        }

        return .{
            .hp = @intCast(new_hp_ev),
            .attack = @intCast(new_attack_ev),
            .defense = @intCast(new_defense_ev),
            .speed = @intCast(new_speed_ev),
            .special_attack = @intCast(new_special_attack_ev),
            .special_defense = @intCast(new_special_defense_ev),
        };
    }

    fn factor_ev(val: u16, factor: f64) u16 {
        return @intFromFloat(@as(f64, @floatFromInt(val)) * factor);
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

pub const SpeciesType = enum(u8) {
    NORMAL = 0,
    FIGHTING = 1,
    FLYING = 2,
    POISON = 3,
    GROUND = 4,
    ROCK = 5,
    BUG = 6,
    GHOST = 7,
    STEEL = 8,
    FIRE = 10,
    WATER = 11,
    GRASS = 12,
    ELECTRIC = 13,
    PSYCHIC = 14,
    ICE = 15,
    DRAGON = 16,
    DARK = 17,
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

    // Regular mon, no special properties
    pub fn regular_mon() @This() {
        return .{
            .is_bad_egg = false,
            .has_species = true,
            .use_egg_name = false,
            .block_box_rs = false
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
    nickname: []const u8,
    language: Language,
    misc_flags: MiscFlags,
    ot_name: []const u8,
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
        return @intCast(@mod(self.personality_value, 25));
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

    fn getGender(self: *const @This()) interface.Gender {
        const species = self.getSpecies();
        const limit_value = species.gender;
        if (limit_value == 0) return .MALE;
        if (limit_value == 254) return .FEMALE;
        if (limit_value == 255) return .UNKNOWN;

        const check_value = @mod(self.personality_value, 256);
        if (check_value >= limit_value) {
            return .MALE;
        } else {
            return .FEMALE;
        }
    }

    fn getSpecies(self: *const @This()) MonSpecies {
        return gen3_species_data[self.dex_number - 1];
    }

    fn getAbility(self: *const @This()) u1 {
        return @mod(self.personality_value, 2);
    }

    fn isShiny(self: *const @This()) bool {
        const ot_id = self.ot_id;
        const ot_id_1: u16 = @truncate(ot_id >> 16);
        const ot_id_2: u16 = @truncate(ot_id);

        const personality_value = self.personality_value;
        const pers_1: u16 = @truncate(personality_value >> 16);
        const pers_2: u16 = @truncate(personality_value);

        const xored = ot_id_1 ^ ot_id_2 ^ pers_1 ^ pers_2;
        return xored < 8;
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

    pub fn allOk() @This() {
        return .{
            .sleep = 0,
            .poison = false,
            .burn = false,
            .freeze = false,
            .paralysis = false,
            .bad_poison = false
        };
    }

    fn toString(self: *const @This()) []const u8 {
        if (self.sleep > 0) {
            return "SLEEP";
        } else if (self.poison) {
            return "POISON";
        } else if (self.burn) {
            return "BURN";
        } else if (self.freeze) {
            return "FREEZE";
        } else if (self.paralysis) {
            return "PARALYSIS";
        } else if (self.bad_poison) {
            return "BAD POISON";
        } else {
            return "-";
        }
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

    fn no_ribbons() @This() {
        return .{
            .cool = 0,
            .beauty= 0,
            .cute= 0,
            .smart= 0,
            .tough= 0,
            .champion= false,
            .winning= false,
            .victory= false,
            .artist= false,
            .effort= false,
            .battle_champion= false,
            .regional_champion= false,
            .national_champion= false,
            .country= false,
            .national= false,
            .earth= false,
            .world= false,
            .obedience= false,
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
            .mail_id = mon_data.mail_id,
            .current_hp = mon_data.current_hp,
            .total_hp = mon_data.total_hp,
            .attack = mon_data.attack,
            .defense = mon_data.defense,
            .speed = mon_data.speed,
            .special_attack = mon_data.special_attack,
            .special_defense = mon_data.special_defense,
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
                .sleep = 0
            },
            .level = level,
            .mail_id = 255, //empty
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

pub const MonParty = struct {
    number_of_mon: u32,
    mons: [6]Mon,

    pub fn init(full_party_data: gen3_data.FullPartyData, allocator: std.mem.Allocator) @This() {
        var mons: [6]Mon = undefined;
        var i: usize = 0;
        while (i < full_party_data.number_of_mon): (i += 1) {
            mons[i] = Mon.fromMonData(full_party_data.mons[i], allocator);
        }

        return MonParty{
            .number_of_mon = full_party_data.number_of_mon,
            .mons = mons
        };
    }

    pub fn printSummary(self: *const @This()) void {
        pok_transfer.bufferedPrint("Number of mon: {d}\n", .{self.number_of_mon});
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            pok_transfer.bufferedPrint("{d}) ", .{i + 1});
            self.mons[i].printShortSummary();
        }
    }

    fn toFullPartyData(self: *const @This()) gen3_data.FullPartyData {
        var result: gen3_data.FullPartyData = undefined;
        result.number_of_mon = self.number_of_mon;
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            result.mons[i] = gen3_data.MonData.fromMon(self.mons[i]);
        }
        return result;
    }
};

pub const MonBox = struct {
    box_number: u8,
    number_of_mon: u8,
    mons: [30]Mon,

    pub fn init(box_number: u8, full_box_data: gen3_data.FullBoxData, allocator: std.mem.Allocator) @This() {
        var mons: [30]Mon = undefined;
        var i: usize = 0;
        while (i < full_box_data.number_of_mons): (i += 1) {
            mons[i] = Mon.fromStrippedMonData(full_box_data.mons[i], allocator);
        }
        return .{
            .box_number = box_number,
            .number_of_mon = full_box_data.number_of_mons,
            .mons = mons
        };
    }

    pub fn printSummary(self: *const @This()) void {
        pok_transfer.bufferedPrint("Box number: {d}\nNumber of mon: {d}\n", .{self.box_number, self.number_of_mon});
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            pok_transfer.bufferedPrint("{d}) ", .{i + 1});
            self.mons[i].printShortSummary();
        }
    }

    pub fn toFullBoxData(self: *const @This()) gen3_data.FullBoxData {
        const number_of_mons = self.number_of_mon;
        var stripped_mons: [gen3_data.mon_per_box]gen3_data.StrippedMonData = undefined;
        var i: usize = 0;
        while (i < number_of_mons): ( i += 1) {
            stripped_mons[i] = gen3_data.StrippedMonData.fromMon(self.mons[i]);
        }
        return .{
            .number_of_mons = number_of_mons,
            .mons = stripped_mons
        };

    }
};

pub const CaughtMon = struct {
    national_dex: bool,
    current_box: u32,
    party: MonParty,
    boxes: [gen3_data.number_of_boxes]MonBox,
    move_mon: interface.MoveMon,

    pub fn init(bytes: []const u8, allocator: std.mem.Allocator) @This() {
        const full_party_data = gen3_data.FullPartyData.init(bytes);
        const mon_party = MonParty.init(full_party_data, allocator);

        const box_bytes = gen3_data.getBoxBytes(bytes);
        var boxes: [gen3_data.number_of_boxes]MonBox = undefined;
        var i: usize = 0;
        while (i < gen3_data.number_of_boxes): ( i += 1) {
            const start = 4 + i*gen3_data.box_size;
            const end = start + gen3_data.box_size;
            const full_box_data = gen3_data.FullBoxData.init(box_bytes[start..end][0..gen3_data.box_size]);
            const mon_box = MonBox.init(@intCast(i + 1), full_box_data, allocator);
            boxes[i] = mon_box;
        }

        return .{
            .national_dex = false,
            .current_box = @bitCast(box_bytes[0..4].*),
            .party = mon_party,
            .boxes = boxes,
            .move_mon = interface.MoveMon.init(6, 30, 14, allocator)
        };
    }

    pub fn printSummary(self: *const@This()) void {
        pok_transfer.bufferedPrint("National dex: {any}, Current box: {d}\nParty size: {d}\nBox 1 size: {d:<5}Box 2 size: {d:<5}Box 3 size: {d:<5}Box 4 size: {d:<5}\nBox 5 size: {d:<5}Box 6 size: {d:<5}Box 7 size: {d:<5}Box 8 size: {d:<5}\nBox 9 size: {d:<5}Box 10 size: {d:<4}Box 11 size: {d:<4}Box 12 size: {d:<4}\nBox 13 size: {d:<4}Box 14 size: {d:<4}",
            .{self.national_dex, self.current_box + 1, self.party.number_of_mon,
                self.boxes[0].number_of_mon, self.boxes[1].number_of_mon, self.boxes[2].number_of_mon, self.boxes[3].number_of_mon,
                self.boxes[4].number_of_mon, self.boxes[5].number_of_mon, self.boxes[6].number_of_mon, self.boxes[7].number_of_mon,
                self.boxes[8].number_of_mon, self.boxes[9].number_of_mon, self.boxes[10].number_of_mon, self.boxes[11].number_of_mon,
                self.boxes[12].number_of_mon, self.boxes[13].number_of_mon
            });
    }

    pub fn printMonDetails(self: *const@This(), box: ?u8, mon: u8) void {
        if (box == null) {
            self.party.mons[mon].printFullSummary();
        } else {
            self.boxes[box.?].mons[mon].printFullSummary();
        }
    }

    pub fn toSave(self: *const@This(), bytes: []u8) void {
        const full_party_bytes = self.party.toFullPartyData().toBytes();
        const party_section_start = gen3_data.getSectionStart(bytes, gen3_data.party_section_id);
        std.mem.copyForwards(u8, bytes[party_section_start + gen3_data.party_offset..], &full_party_bytes);

        var full_box_datas: [number_of_boxes]gen3_data.FullBoxData = undefined;
        var i: usize = 0;
        while (i < full_box_datas.len): ( i += 1) {
            full_box_datas[i] = self.boxes[i].toFullBoxData();
        }

        const box_bytes = gen3_data.boxesToBoxBytes(self.current_box, full_box_datas, bytes);
        var j: usize = 5;
        while (j < gen3_data.last_box_section_id): (j += 1) {
            const section_start = gen3_data.getSectionStart(bytes, @intCast(j));
            const source_start= (j - 5) * gen3_data.box_section_size;
            const source_end = source_start + gen3_data.box_section_size;
            std.mem.copyForwards(u8, bytes[section_start..], box_bytes[source_start..source_end]);
        }

        const last_section_start = gen3_data.getSectionStart(bytes, gen3_data.last_box_section_id);
        const source_start = 8 * gen3_data.box_section_size;
        const source_end = source_start + gen3_data.last_box_section_size;
        std.mem.copyForwards(u8, bytes[last_section_start..], box_bytes[source_start..source_end]);

        gen3_data.processDexToSave(self, bytes);

        gen3_data.fixChecksums(bytes);
    }

    pub fn getVersion(self: *const@This()) versions.Version {
        _ = self;
        return .GEN3FRLG;
    }

    pub fn removeMon(self: *@This(), box: ?u8, mon: u8) void {
        if (box == null) {
            if (box.? != party_size - 1) {
                var i: usize = @intCast(mon);
                while (i < party_size - 1): (i += 1) {
                    self.party.mons[i] = self.party.mons[i + 1];
                }
            }
            self.party.number_of_mon -= 1;
        } else {
            if (mon != box_size - 1) {
                var i: usize = mon;
                while (i < box_size - 1): (i += 1) {
                    self.boxes[box.?].mons[i] = self.boxes[box.?].mons[i + 1];
                }
            }
            self.boxes[box.?].number_of_mon -= 1;
        }
    }

    pub fn insertMon(self: *@This(), mon: interface.MonInterface) !void {
        var i: usize = 0;
        const mon_insert = try Mon.fromMonInterface(mon);
        if (mon_insert.base_data.dex_number > 151 and !self.national_dex) {
            return error.NationalDexNotUnlocked;
        }

        while(i < number_of_boxes): (i += 1) {
            if (self.boxes[i].number_of_mon < gen3_data.mon_per_box) {
                self.boxes[i].mons[self.boxes[i].number_of_mon] = mon_insert;
                self.boxes[i].number_of_mon += 1;
                return;
            }
        }
        return error.OutOfSpace;
    }

    pub fn getFreeSpace(self: *const@This()) u16 {
        var free: u16 = number_of_boxes*box_size;
        for (self.boxes) |box| {
            free -= box.number_of_mon;
        }
        return free;
    }

    pub fn getMon(self: *const@This(), box: ?u8, mon: u8) Mon {
        if (box == null) {
            return self.party.mons[mon];
        } else {
            return self.boxes[box.?].mons[mon];
        }
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
    var i: usize = 1;
    while (i <= 100): ( i += 1) {
        const required: usize = (i*i*i);
        if (required > xp) {
            return @intCast(i - 1);
        }
    }
    return 100;
}

fn erratic_level(xp: u32) u8 {
    var i: usize = 3;
    while (i < 50): (i += 1) {
        const required: usize = ((i*i*i)*(100 - i))/50;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }

    while (i < 68): (i += 1) {
        const required: usize = ((i*i*i)*(150 - i))/100;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }

    while (i < 98): (i += 1) {
        const required: usize = ((i*i*i)*((1911-10*i)/3))/500;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }

    while (i <= 100): (i += 1) {
        const required: usize = ((i*i*i)*(160 - i))/100;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }

    return 100;
}

fn fluctuating_level(xp: u32) u8 {
    var i: usize = 3;
    while (i < 15): (i += 1) {
        const required: usize = ((i*i*i)*(24+((i + 1)/3)))/50;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }

    while (i < 36): (i += 1) {
        const required: usize = ((i*i*i)*(i + 14))/50;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }

    while (i <= 100): (i += 1) {
        const required: usize = ((i*i*i)*(32+((i + 0)/2)))/50;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }
    return 100;
}

fn medium_slow_level(xp: u32) u8 {
    if (xp < 9) return 1;
    if (xp < 57) return 2;
    if (xp < 96) return 3; // prevents underflow of calculation for low levels
    var i: usize = 3;
    while (i <= 100): ( i += 1) {
        const required: usize = ((i*i*i)*6)/5 - (i*i)*15 + 100 * i - 140;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }
    return 100;
}

fn fast_level(xp: u32) u8 {
    var i: usize = 1;
    while (i <= 100): ( i += 1) {
        const required: usize = ((i*i*i)*4)/5;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }
    return 100;
}

fn slow_level(xp: u32) u8 {
    var i: usize = 1;
    while (i <= 100): ( i += 1) {
        const required: usize = ((i*i*i)*5)/4;
        if (required > xp) {
            return @intCast(i - 1);
        }
    }
    return 100;
}

fn calculate_max_hp(base_stat: u16, iv: u8, ev: u8, level: u8) u16 {
   return ((((ev/4) + iv + (2*base_stat)) * level) / 100) + level + 10;
}

fn calculate_other_stat(base_stat: u16, iv: u8, ev: u8, level: u8, nature: f64) u16 {
    const base: f64 = @floatFromInt(((((ev/4) + iv + (2*base_stat)) * level) / 100) + 5);
    return @intFromFloat(base * nature);
}

pub const Mon = struct {
    base_data: MonBaseData,
    stats: Stats,

    pub fn fromStrippedMonData(stripped_mon_data: gen3_data.StrippedMonData, allocator: std.mem.Allocator) @This() {
        const mon_base_data = MonBaseData.fromStrippedMonData(stripped_mon_data, allocator);
        const stats = Stats.fromMonBaseData(mon_base_data);
        return .{
            .base_data = mon_base_data,
            .stats = stats
        };
    }

    pub fn fromMonData(mon_data: gen3_data.MonData, allocator: std.mem.Allocator) @This() {
        return .{
            .base_data = MonBaseData.fromStrippedMonData(mon_data.stripped_mon_data, allocator),
            .stats = Stats.fromMonData(mon_data)
        };
    }

    fn fromGen1(mon: @import("../gen1/mon.zig").Mon) @This() {
        const ot_id_bytes = std.mem.asBytes(&mon.base_data.ot_number);
        const ot_id = enrich_ot_id(mon.base_data.ot_number);
        const randomness = std.crypto.hash.Md5.hashResult(&[_]u8{mon.base_data.ivs.special, mon.base_data.ivs.attack, mon.base_data.ivs.defense, mon.base_data.ivs.speed, ot_id_bytes[0], ot_id_bytes[1]});
        const personality_value: u32 = determine_personality_value(ot_id, mon.base_data.dex_number, mon.isShiny(), mon.getGender(), randomness);
        const ev_randomness = randomness[4];


        return Mon{
              .base_data = .{
                    .personality_value = personality_value,
                    .ot_id = ot_id,
                    .nickname = mon.base_data.name,
                    .language = .ENGLISH,
                    .misc_flags = MiscFlags.regular_mon(),
                    .ot_name = mon.base_data.ot_name,
                    .markings = 0,
                    .checksum = 0, // should be fixed during conversion
                    .unknown0 = 0,
                    .dex_number = mon.base_data.dex_number,
                    .item_held = 0,
                    .experience = mon.base_data.experience_points,
                    .pp_bonuses = .{mon.base_data.move_pps[0].applied_pp_up, mon.base_data.move_pps[1].applied_pp_up, mon.base_data.move_pps[2].applied_pp_up, mon.base_data.move_pps[3].applied_pp_up},
                    .friendship = 70,
                    .moves = mon.base_data.moves,
                    .pps = .{mon.base_data.move_pps[0].current_pp, mon.base_data.move_pps[1].current_pp, mon.base_data.move_pps[2].current_pp, mon.base_data.move_pps[3].current_pp},
                    .ev = EV.fromGen1(mon.base_data.evs),
                    .contest_stats = ContestStats.no_stats(),
                    .pokerus = 0,
                    .met_location = 254, //in-game trade
                    .origins_info = .{
                      .level_met = @intCast(mon.base_data.level),
                      .origin_game = 4, // Fire Red
                      .pokeball_type = 4, // standard ball
                      .trainer_is_female = false
                  },
                    .iv_egg_ability = .{
                        .hp_iv = @as(u5, mon.base_data.ivs.special) * 2 + getRandomness(ev_randomness, 0),
                        .attack_iv = @as(u5, mon.base_data.ivs.attack) * 2 + getRandomness(ev_randomness, 1),
                        .defense_iv = @as(u5, mon.base_data.ivs.defense) * 2 + getRandomness(ev_randomness, 2),
                        .speed_iv = @as(u5, mon.base_data.ivs.speed) * 2 + getRandomness(ev_randomness, 3),
                        .special_attack_iv = @as(u5, mon.base_data.ivs.special) * 2 + getRandomness(ev_randomness, 4),
                        .special_defense_iv = @as(u5, mon.base_data.ivs.special) * 2 + getRandomness(ev_randomness, 5),
                        .egg = false,
                        .ability = 0
                    },
                    .ribbons_obedience = Ribbons.no_ribbons(),
              },
              .stats = .{
                    .status_condition = StatusCondition.allOk(),
                    .level = mon.base_data.level,
                    .mail_id = 255, //empty
                    .current_hp = mon.stats.max_hp,
                    .total_hp = mon.stats.max_hp,
                    .attack = mon.stats.attack,
                    .defense = mon.stats.defense,
                    .speed = mon.stats.speed,
                    .special_attack = mon.stats.special,  // v
                    .special_defense = mon.stats.special, // These values are not correct but not used in box and recalculated when removed from box
              }
        };
    }

    fn fromGen2(mon: @import("../gen2GS/mon.zig").Mon) @This() {
        const ot_id_bytes = std.mem.asBytes(&mon.base_data.ot_number);
        const ot_id = enrich_ot_id(mon.base_data.ot_number);
        const randomness = std.crypto.hash.Md5.hashResult(&[_]u8{mon.base_data.ivs.special, mon.base_data.ivs.attack, mon.base_data.ivs.defense, mon.base_data.ivs.speed, ot_id_bytes[0], ot_id_bytes[1]});
        const personality_value: u32 = determine_personality_value(ot_id, mon.base_data.dex_number, mon.isShiny(), mon.getGender(), randomness);
        const ev_randomness = randomness[4];

        return Mon{
            .base_data = .{
                .personality_value = personality_value,
                .ot_id = ot_id,
                .nickname = mon.base_data.name,
                .language = .ENGLISH,
                .misc_flags = MiscFlags.regular_mon(),
                .ot_name = mon.base_data.ot_name,
                .markings = 0,
                .checksum = 0, // should be fixed during conversion
                .unknown0 = 0,
                .dex_number = mon.base_data.dex_number,
                .item_held = 0,
                .experience = mon.base_data.experience_points,
                .pp_bonuses = .{mon.base_data.move_pps[0].applied_pp_up, mon.base_data.move_pps[1].applied_pp_up, mon.base_data.move_pps[2].applied_pp_up, mon.base_data.move_pps[3].applied_pp_up},
                .friendship = 70,
                .moves = mon.base_data.moves,
                .pps = .{mon.base_data.move_pps[0].current_pp, mon.base_data.move_pps[1].current_pp, mon.base_data.move_pps[2].current_pp, mon.base_data.move_pps[3].current_pp},
                .ev = EV.fromGen2(mon.base_data.evs),
                .contest_stats = ContestStats.no_stats(),
                .pokerus = 0,
                .met_location = 254, //in-game trade
                .origins_info = .{
                    .level_met = @intCast(mon.base_data.level),
                    .origin_game = 4, // Fire Red
                      .pokeball_type = 4, // standard ball
                      .trainer_is_female = false
                },
                .iv_egg_ability = .{
                    .hp_iv = @as(u5, mon.base_data.ivs.special) * 2 + getRandomness(ev_randomness, 0),
                    .attack_iv = @as(u5, mon.base_data.ivs.attack) * 2 + getRandomness(ev_randomness, 1),
                    .defense_iv = @as(u5, mon.base_data.ivs.defense) * 2 + getRandomness(ev_randomness, 2),
                    .speed_iv = @as(u5, mon.base_data.ivs.speed) * 2 + getRandomness(ev_randomness, 3),
                    .special_attack_iv = @as(u5, mon.base_data.ivs.special) * 2 + getRandomness(ev_randomness, 4),
                    .special_defense_iv = @as(u5, mon.base_data.ivs.special) * 2 + getRandomness(ev_randomness, 5),
                    .egg = false,
                    .ability = 0
                },
                .ribbons_obedience = Ribbons.no_ribbons(),
            },
            .stats = .{
                .status_condition = StatusCondition.allOk(),
                .level = mon.base_data.level,
                .mail_id = 255, //empty
                    .current_hp = mon.stats.max_hp,
                .total_hp = mon.stats.max_hp,
                .attack = mon.stats.attack,
                .defense = mon.stats.defense,
                .speed = mon.stats.speed,
                .special_attack = mon.stats.special_attack,
                    .special_defense = mon.stats.special_defense,
              }
        };
    }

    pub fn fromMonInterface(mon_interface: interface.MonInterface) !@This() {
        switch (mon_interface) {
            .gen1 => {
                return fromGen1(mon_interface.gen1);
            },
            .gen2gs => {
                return fromGen2(mon_interface.gen2gs);
            },
            .gen3frlg => {
                return mon_interface.gen3frlg;
            }
        }

    }

    pub fn printFullSummary(self: *const @This()) void {
        const type_name = @import("../general/names.zig").mon_names[self.base_data.dex_number - 1];
        const condition:[]const u8 = self.stats.status_condition.toString();
        const species = gen3_species_data[self.base_data.dex_number - 1];

        pok_transfer.bufferedPrint("{s}, lvl. {d} {s} {s}", .{self.base_data.nickname, self.stats.level, type_name, self.getGenderSymbol()});
        if (species.type1 != species.type2) {
            pok_transfer.bufferedPrint("({s}/{s})", .{@tagName(@as(SpeciesType, @enumFromInt(species.type1))), @tagName(@as(SpeciesType, @enumFromInt(species.type2)))});
        } else {
            pok_transfer.bufferedPrint("({s})", .{@tagName(@as(SpeciesType, @enumFromInt(species.type1)))});
        }

        const hp_exp = "HP: {d}/{d} Exp: {d} Condition: {s}";
        const ot = "OT: {s} ({d}) Friendship: {d}/255";
        const moves_str = "Move 1: {s} Move 2: {s}\nMove 3: {s} Move 4: {s}";
        const stats = "HP: {d} Attack: {d} Defense: {d} Speed: {d} Special Attack: {d} Special Defense {d}";
        const ivs = "Attack IV: {d} Defense IV: {d} Speed IV: {d} Special Attack IV: {d} Special Defense IV: {d}";
        const evs = "HP EV: {d} Attack EV: {d} Defense EV: {d} Speed EV: {d} Special Attack EV: {d} Special Defense EV: {d}";
        const contest_stats_str = "Coolness: {d} Beauty: {d} Cuteness: {d} Smartness: {d} Toughness: {d} Feel: {d}";

        const iv_obj = self.base_data.iv_egg_ability;
        const ev_obj = self.base_data.ev;
        const contest_stats = self.base_data.contest_stats;

        const move1_str = if (self.base_data.moves[0] != null) self.base_data.moves[0].?.name else "-";
        const move2_str = if (self.base_data.moves[1] != null) self.base_data.moves[1].?.name else "-";
        const move3_str = if (self.base_data.moves[2] != null) self.base_data.moves[2].?.name else "-";
        const move4_str = if (self.base_data.moves[3] != null) self.base_data.moves[3].?.name else "-";

        pok_transfer.bufferedPrint( "\n" ++ hp_exp ++ "\n" ++ ot ++ "\n" ++ moves_str ++ "\n" ++ stats ++ "\n" ++ ivs ++ "\n" ++ evs, .{
            self.stats.current_hp, self.stats.total_hp, self.base_data.experience, condition,
            self.base_data.ot_name, self.base_data.ot_id, self.base_data.friendship,
            move1_str, move2_str, move3_str, move4_str,
            self.stats.total_hp, self.stats.attack, self.stats.defense, self.stats.speed, self.stats.special_attack, self.stats.special_defense,
            iv_obj.attack_iv, iv_obj.defense_iv, iv_obj.speed_iv, iv_obj.special_attack_iv, iv_obj.special_defense_iv,
            ev_obj.hp, ev_obj.attack, ev_obj.defense, ev_obj.speed, ev_obj.special_attack, ev_obj.special_defense
            });

        pok_transfer.bufferedPrint("\n" ++ contest_stats_str, .{
            contest_stats.coolness, contest_stats.beauty, contest_stats.cuteness, contest_stats.smartness, contest_stats.toughness, contest_stats.feel});
    }

    pub fn printShortSummary(self: *const @This()) void {
        pok_transfer.bufferedPrint("{s}, lvl. {d} {s} {s}\n", .{self.base_data.nickname, self.stats.level, @import("../general/names.zig").mon_names[self.base_data.dex_number - 1], self.getGenderSymbol()});
    }

    fn getGenderSymbol(self: *const @This()) []const u8 {
        const gender = self.base_data.getGender();
        if (gender == .MALE) {
            return "♂";
        } else if (gender == .FEMALE) {
            return "♀";
        } else {
            return "";
        }
    }

    pub fn generate(dex_number: u16, gender: interface.Gender, shiny: bool, ot_id: u32, attack_iv: u5, defense_iv: u5, speed_iv: u5, hp_iv: u5, special_attack_iv: u5, special_defense_iv: u5) @This() {
        var prng = std.Random.DefaultPrng.init(@as(u64, @truncate(@abs(std.time.nanoTimestamp()))));
        var random: [16]u8 = undefined;
        prng.fill(random[0..]);

        const personality_value: u32 = determine_personality_value(ot_id, dex_number, shiny, gender, random);
        const base_data: MonBaseData = .{
            .personality_value = personality_value,
            .ot_id = ot_id,
            .nickname = "JOHN",
            .language = .ENGLISH,
            .misc_flags = MiscFlags.regular_mon(),
            .ot_name ="BILL",
            .markings = 0,
            .checksum = 0, // should be fixed during conversion
                .unknown0 = 0,
            .dex_number = dex_number,
            .item_held = 0,
            .experience = 30,
            .pp_bonuses = .{0, 0, 0, 0},
            .friendship = 70,
            .moves = .{&moves_ns.moves[149], null, null, null},
            .pps = .{0, 0, 0, 0},
            .ev = .{
                .attack = 0,
                .defense = 0,
                .hp = 0,
                .speed = 0,
                .special_attack = 0,
                .special_defense = 0
            },
            .contest_stats = ContestStats.no_stats(),
            .pokerus = 0,
            .met_location = 254, //in-game trade
                .origins_info = .{
                .level_met = @intCast(2),
                .origin_game = 4, // Fire Red
                      .pokeball_type = 4, // standard ball
                      .trainer_is_female = false
            },
            .iv_egg_ability = .{
                .hp_iv = hp_iv,
                .attack_iv = attack_iv,
                .defense_iv = defense_iv,
                .speed_iv = speed_iv,
                .special_attack_iv = special_attack_iv,
                .special_defense_iv = special_defense_iv,
                .egg = false,
                .ability = 0
            },
            .ribbons_obedience = Ribbons.no_ribbons(),
        };
        const stats = Stats.fromMonBaseData(base_data);
        return .{
            .base_data = base_data,
            .stats = stats
        };
    }
};

pub fn enrich_ot_id(old_ot_id: u16) u32 {
    const secret_source = std.crypto.hash.Md5.hashResult(std.mem.asBytes(&old_ot_id));
    const secret = secret_source[14..16][0..2].*;
    const secret_word: u16 = @bitCast(secret);
    return (@as(u32, secret_word) << 16) + old_ot_id;
}

fn getRandomness(randomness_byte: u8, bit: u3) u1 {
    return @intCast((randomness_byte >> bit) & 1);
}

fn determine_personality_value(ot_id: u32, dex_number: u16, shiny: bool, gender: interface.Gender, randomness: [16]u8) u32{
    const shiny_calc = @as(u16, @intCast(ot_id >> 16)) ^ @as(u16, @truncate(ot_id));
    var gender_byte: u8 = undefined;
    const second_byte: u8 = randomness[1];

    if (gender != .UNKNOWN) {
        const species = gen3_species_data[dex_number - 1];
        const limit_value = species.gender;
        if (limit_value == 0 or limit_value == 254) {
            gender_byte = randomness[0];
        } else {
            if (gender == .MALE) {
                gender_byte = limit_value + @mod(randomness[0], (255 - limit_value));
            } else {
                gender_byte =  limit_value - 1 - @mod(randomness[0], limit_value - 1);
            }
        }
    } else {
        gender_byte = randomness[0];
    }

    const lower_half = @as(u16, gender_byte) + (@as(u16, second_byte) << 8);
    var upper_half = shiny_calc ^ lower_half; // Not modifying this guarantees a zero remainder shiny (S = 0)
    const upper_half_randomness: u16 = @bitCast([2]u8{randomness[2], randomness[3]});

    if (shiny) {
        upper_half = upper_half ^ @mod(upper_half_randomness, 8); // only change last 3 bits, guarantees shinyness
    } else {
        upper_half = upper_half ^ (8 + @mod(upper_half_randomness, 65535 - 8));
    }
    const result = (@as(u32, upper_half) << 16) + lower_half;
    return result;
}