const std = @import("std");

const encoding = @import("encoding.zig");
const moves_ns = @import("../general/moves.zig");
const gen2data = @import("./save_datastructure.zig");
const interface = @import("../general/interface.zig");
const versions = @import("../general/versions.zig");
const gen1 = @import("../gen1/mon.zig");
const gen3 = @import("../gen3FRLG/mon.zig");

const pok_transfer = @import("../root.zig");

pub const gen2_species_data: *const[251]MonSpecies = std.mem.bytesAsValue([251]MonSpecies, @embedFile("species.dat"));

pub const party_size = 6;
pub const box_size = 20;
pub const number_of_boxes = 14;

pub const default_friendship = 70;

pub const save_size = gen2data.save_size;

pub const Statuses = struct {
    asleep: bool,
    poisoned: bool,
    burned: bool,
    frozen: bool,
    paralyzed: bool,

    pub fn init(gen2_status: u8) @This() {
        return .{
            .asleep = gen2_status >> 2 == 1,
            .poisoned = gen2_status >> 3 == 1,
            .burned = gen2_status >> 4 == 1,
            .frozen = gen2_status >> 5 == 1,
            .paralyzed = gen2_status >> 6 == 1
        };
    }

    pub fn toNumber(self: @This()) u8 {
        return @as(u8, @intFromBool(self.asleep)) << 2 | @as(u8, @intFromBool(self.poisoned)) << 3 | @as(u8, @intFromBool(self.burned)) << 4 | @as(u8, @intFromBool(self.frozen)) << 5 | @as(u8, @intFromBool(self.paralyzed)) << 6;
    }

    pub fn toString(self: @This()) []const u8 {
        var condition:[]const u8 = "-";
        if (self.asleep) {
            condition = "ASLEEP";
        } else if (self.poisoned) {
            condition = "POISONED";
        } else if (self.burned) {
            condition = "BURNED";
        } else if (self.frozen) {
            condition = "FROZEN";
        } else if (self.paralyzed) {
            condition = "PARALYZED";
        }
        return condition;
    }
};

pub const EV = struct {
    hp: u16,
    attack: u16,
    defense: u16,
    speed: u16,
    special: u16,

    pub fn fromGen1(ev: gen1.EV) @This() {
        return .{
            .hp = ev.hp,
            .attack = ev.attack,
            .defense = ev.defense,
            .speed = ev.speed,
            .special = ev.special
        };
    }
};

pub const IV = struct {
    attack: u4,
    defense: u4,
    speed: u4,
    special: u4,

    pub fn fromGen1(iv: gen1.IV) @This() {
        return .{
            .attack = iv.attack,
            .defense = iv.defense,
            .speed = iv.speed,
            .special = iv.special
        };
    }

};

pub const MonPP = struct {
    applied_pp_up: u2,
    current_pp: u6,

    pub fn init(gen2_mon_pp: gen2data.MonPP) @This() {
        return .{
            .applied_pp_up = gen2_mon_pp.applied_ppup,
            .current_pp = gen2_mon_pp.current_pp
        };
    }

    pub fn toGen2Number(self: @This()) u8 {
        return self.current_pp | @as(u8, self.applied_pp_up) << 6;
    }

    pub fn toMonPP(self: @This()) gen2data.MonPP {
        return .{
            .applied_ppup = self.applied_pp_up,
            .current_pp = self.current_pp
        };
    }

    pub fn fromGen1(gen1_monpp: gen1.MonPP) @This() {
        return .{
            .applied_pp_up = gen1_monpp.applied_pp_up,
            .current_pp = gen1_monpp.current_pp
        };
    }
};

pub const Gender = enum {
    MALE,
    FEMALE,
    UNKNOWN
};


pub const SpeciesType = enum(u8) {
    NORMAL = 0,
    FIGHTING = 1,
    FLYING = 2,
    POISON = 3,
    GROUND = 4,
    ROCK = 5,
    BIRD = 6,
    BUG = 7,
    GHOST = 8,
    STEEL = 9,
    FIRE = 20,
    WATER = 21,
    GRASS = 22,
    ELECTRIC = 23,
    PSYCHIC = 24,
    ICE = 25,
    DRAGON = 26,
    DARK = 27,
};

fn speciesTypeFromNumber(number: u8) SpeciesType {
    return switch (number) {
        0 => .NORMAL,
        1 => .FIGHTING,
        2 => .FLYING,
        3 => .POISON,
        4 => .GROUND,
        5 => .ROCK,
        6 => .BIRD,
        7 => .BUG,
        8 => .GHOST,
        9 => .STEEL,
        20 => .FIRE,
        21 => .WATER,
        22 => .GRASS,
        23 => .ELECTRIC,
        24 => .PSYCHIC,
        25 => .ICE,
        26 => .DRAGON,
        27 => .DARK,
        else => .NORMAL
    };
}

pub const Mon = struct {
    base_data: MonBaseData,
    stats: Stats,

    pub fn fromMonData(mon_data: gen2data.MonData, mon_name: [11]u8, ot_name: [11]u8, allocator: std.mem.Allocator) @This() {
        return .{
            .base_data = MonBaseData.init(mon_data.stripped_mon_data, mon_name, ot_name, allocator),
            .stats = .{
                .statuses = Statuses.init(mon_data.status_condition),
                .current_hp = @byteSwap(mon_data.current_hp),
                .max_hp = @byteSwap(mon_data.max_hp),
                .attack = @byteSwap(mon_data.attack),
                .defense = @byteSwap(mon_data.defense),
                .speed = @byteSwap(mon_data.speed),
                .special_attack = @byteSwap(mon_data.special_attack),
                .special_defense = @byteSwap(mon_data.special_defense),
            }
        };
    }

    pub fn toStrippedMonData(self: *const @This()) gen2data.StrippedMonData {
        return .{
            .index_number = self.base_data.dex_number,
            .held_item_number = self.base_data.held_item,
            .move_1 = if (self.base_data.moves[0] != null) @intCast(self.base_data.moves[0].?.id) else 0,
            .move_2 = if (self.base_data.moves[1] != null) @intCast(self.base_data.moves[1].?.id) else 0,
            .move_3 = if (self.base_data.moves[2] != null) @intCast(self.base_data.moves[2].?.id) else 0,
            .move_4 = if (self.base_data.moves[3] != null) @intCast(self.base_data.moves[3].?.id) else 0,
            .ot_number = @byteSwap(self.base_data.ot_number),
            .experience_points = @byteSwap(self.base_data.experience_points),
            .hp_ev = @byteSwap(self.base_data.evs.hp),
            .attack_ev = @byteSwap(self.base_data.evs.attack),
            .defense_ev = @byteSwap(self.base_data.evs.defense),
            .speed_ev = @byteSwap(self.base_data.evs.speed),
            .special_ev = @byteSwap(self.base_data.evs.special),
            .iv_attack = self.base_data.ivs.attack,
            .iv_defense = self.base_data.ivs.defense,
            .iv_speed = self.base_data.ivs.speed,
            .iv_special = self.base_data.ivs.special,
            .pp_1 = self.base_data.move_pps[0].toMonPP(),
            .pp_2 = self.base_data.move_pps[1].toMonPP(),
            .pp_3 = self.base_data.move_pps[2].toMonPP(),
            .pp_4 = self.base_data.move_pps[3].toMonPP(),
            .friendship_eggcycles = self.base_data.friendship_eggcycles,
            .pokerus = self.base_data.pokerus,
            .caught_data = @byteSwap(self.base_data.caught_data),
            .level = self.base_data.level,
        };
    }

    pub fn toMonData(self: *const @This()) gen2data.MonData {
        return .{
            .stripped_mon_data = self.toStrippedMonData(),
            .status_condition = self.stats.statuses.toNumber(),
            .current_hp = @byteSwap(self.stats.current_hp),
            .max_hp = @byteSwap(self.stats.max_hp),
            .attack = @byteSwap(self.stats.attack),
            .defense = @byteSwap(self.stats.defense),
            .speed = @byteSwap(self.stats.speed),
            .special_attack = @byteSwap(self.stats.special_attack),
            .special_defense = @byteSwap(self.stats.special_defense)
        };
    }

    pub fn fromStrippedMonData(mon_data: gen2data.StrippedMonData, mon_name: [11]u8, ot_name: [11]u8, allocator: std.mem.Allocator) @This() {
        const mon_base_data = MonBaseData.init(mon_data, mon_name, ot_name, allocator);
        return .{
            .base_data = mon_base_data,
            .stats = Stats.fromMonBaseData(mon_base_data)
        };
    }

    pub fn getGender(self: @This()) Gender {
        const species = gen2_species_data[self.base_data.dex_number - 1];
        const gender_ratio = species.gender_ratio;
        const attack = self.base_data.ivs.attack;
        if (gender_ratio == 0) {
            return .MALE;
        } else if (gender_ratio == 31) {
            return if (attack >= 2) .MALE else .FEMALE;
        } else if (gender_ratio == 63) {
            return if (attack >= 4) .MALE else .FEMALE;
        } else if (gender_ratio == 127) {
            return if (attack >= 8) .MALE else .FEMALE;
        } else if (gender_ratio == 191) {
            return if (attack >= 12) .MALE else .FEMALE;
        } else if (gender_ratio == 254) {
            return .FEMALE;
        } else if (gender_ratio == 255) {
            return .UNKNOWN;
        } else {
            return .UNKNOWN;
        }
    }

    pub fn isShiny(self: @This()) bool {
        if (self.base_data.ivs.defense != 10 or self.base_data.ivs.speed != 10 or self.base_data.ivs.special) {
            return false;
        }
        const matches: []u8 = .{2, 3, 6, 7, 10, 11, 14, 15};
        for (matches) |match| {
            if (self.base_data.ivs.attack == match) {
                return true;
            }
        }
        return false;
    }

    pub fn unownLetter(self: @This()) u8 {
        // A=0, B=1 .... Z=25
        const calculated = ((self.base_data.ivs.attack & 6) << 5) | ((self.base_data.ivs.defense & 6) << 3) | ((self.base_data.ivs.speed & 6) << 1) | ((self.base_data.ivs.special & 6) >> 1);
        return calculated / 10;
    }

    fn getGenderSymbol(self: *const @This()) []const u8{
        const gender = self.getGender();
        if (gender == .MALE) {
            return "♂";
        } else if (gender == .FEMALE) {
            return "♀";
        } else {
            return "";
        }
    }

    pub fn printShortSummary(self: *const @This()) void {
        pok_transfer.bufferedPrint("{s}, lvl. {d} {s} {s}\n", .{self.base_data.name, self.base_data.level, @import("../general/names.zig").mon_names[self.base_data.dex_number - 1], self.getGenderSymbol()});
    }

    fn fromMonInterface(mon_interface: interface.MonInterface) !@This() {
        switch (mon_interface) {
            .gen1 => {
                return fromGen1(mon_interface.gen1);
            },
            .gen2gs => {
                return mon_interface.gen2gs;
            },
            .gen3frlg => {
                return fromGen3(mon_interface.gen3frlg);
            }
        }
    }

    fn fromGen1(mon: gen1.Mon) @This() {
        const base_data: MonBaseData = .{
            .dex_number = mon.base_data.dex_number,
            .name = mon.base_data.name,
            .level = mon.base_data.level,
            .held_item = 0,
            .moves = mon.base_data.moves,
            .ot_number = mon.base_data.ot_number,
            .ot_name = mon.base_data.ot_name,
            .experience_points = mon.base_data.experience_points,
            .evs = EV.fromGen1(mon.base_data.evs),
            .ivs = IV.fromGen1(mon.base_data.ivs),
            .move_pps = .{MonPP.fromGen1(mon.base_data.move_pps[0]),MonPP.fromGen1(mon.base_data.move_pps[1]),MonPP.fromGen1(mon.base_data.move_pps[2]),MonPP.fromGen1(mon.base_data.move_pps[3])},
            .friendship_eggcycles = default_friendship,
            .pokerus = 0,
            .caught_data = 0,
        };

        return Mon{
            .base_data = base_data,
            .stats = Stats.fromMonBaseData(base_data)
        };
    }

    fn fromGen3(mon: gen3.Mon) @This() {
        _ = mon;
        unreachable;
    }

    pub fn printFullSummary(self: *const @This()) void {
        const type_name = @import("../general/names.zig").mon_names[self.base_data.dex_number - 1];
        const condition:[]const u8 = self.stats.statuses.toString();
        const species = gen2_species_data[self.base_data.dex_number - 1];

        pok_transfer.bufferedPrint("{s}, lvl. {d} {s} {s}", .{self.base_data.name, self.base_data.level, type_name, self.getGenderSymbol()});
        if (species.type1 != species.type2) {
            pok_transfer.bufferedPrint("({s}/{s})", .{@tagName(speciesTypeFromNumber(species.type1)), @tagName(speciesTypeFromNumber(species.type2))});
        } else {
           pok_transfer.bufferedPrint("({s})", .{@tagName(speciesTypeFromNumber(species.type1))});
        }

        const hp_exp = "HP: {d}/{d} Exp: {d} Condition: {s}";
        const ot = "OT: {s} ({d}) Friendship: {d}/255";
        const moves_str = "Move 1: {s} Move 2: {s}\nMove 3: {s} Move 4: {s}";
        const stats = "HP: {d} Attack: {d} Defense: {d} Speed: {d} Special Attack: {d} Special Defense {d}";
        const ivs = "Attack IV: {d} Defense IV: {d} Speed IV: {d} Special IV: {d}";
        const evs = "HP EV: {d} Attack EV: {d} Defense EV: {d} Speed EV: {d} Special EV: {d}";

        const iv_obj = self.base_data.ivs;
        const ev_obj = self.base_data.evs;

        const move1_str = if (self.base_data.moves[0] != null) self.base_data.moves[0].?.name else "-";
        const move2_str = if (self.base_data.moves[1] != null) self.base_data.moves[1].?.name else "-";
        const move3_str = if (self.base_data.moves[2] != null) self.base_data.moves[2].?.name else "-";
        const move4_str = if (self.base_data.moves[3] != null) self.base_data.moves[3].?.name else "-";

        pok_transfer.bufferedPrint( "\n" ++ hp_exp ++ "\n" ++ ot ++ "\n" ++ moves_str ++ "\n" ++ stats ++ "\n" ++ ivs ++ "\n" ++ evs, .{
            self.stats.current_hp, self.stats.max_hp, self.base_data.experience_points, condition,
            self.base_data.ot_name, self.base_data.ot_number, self.base_data.friendship_eggcycles,
            move1_str, move2_str, move3_str, move4_str,
            self.stats.max_hp, self.stats.attack, self.stats.defense, self.stats.speed, self.stats.special_attack, self.stats.special_defense,
            iv_obj.attack, iv_obj.defense, iv_obj.speed, iv_obj.special,
            ev_obj.hp, ev_obj.attack, ev_obj.defense, ev_obj.speed, ev_obj.special
        });
    }

};

pub const MonParty = struct {
    number_of_mon: u8,
    mons: [6]Mon,

    pub fn init(full_party_data: gen2data.FullPartyData, allocator: std.mem.Allocator) @This() {
        var mons: [6]Mon = undefined;
        const data_mons = full_party_data.getMons();
        const names = full_party_data.getNames();
        const ot_names = full_party_data.getOtNames();

        var i: usize = 0;
        while (i < 6): (i += 1) {
            mons[i] = Mon.fromMonData(data_mons[i], names[i].toBytes(), ot_names[i].toBytes(), allocator);
        }

        return .{
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

    pub fn toFullPartyData(self: *const @This()) gen2data.FullPartyData {
        var species: [6]u8 = undefined;
        var ot_names: [6][11]u8 = undefined;
        var mon_names: [6][11]u8 = undefined;
        var mons: [6]gen2data.MonData = undefined;

        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            species[i] = self.mons[i].base_data.dex_number;
            ot_names[i] = encoding.utf8ToGen2(self.mons[i].base_data.ot_name);
            mon_names[i] = encoding.utf8ToGen2(self.mons[i].base_data.name);
            mons[i] = self.mons[i].toMonData();
        }

        while (i < party_size): (i += 1) {
            species[i] = 255;
            ot_names[i] = .{80} ** 11;
            mon_names[i] = .{80} ** 11;
        }

        return gen2data.FullPartyData{
            .number_of_mon = self.number_of_mon,
            .mon1_species = species[0],
            .mon2_species = species[1],
            .mon3_species = species[2],
            .mon4_species = species[3],
            .mon5_species = species[4],
            .mon6_species = species[5],
            .padding0 = 255,
            .mon1 = mons[0],
            .mon2 = mons[1],
            .mon3 = mons[2],
            .mon4 = mons[3],
            .mon5 = mons[4],
            .mon6 = mons[5],
            .mon1_ot_name = @bitCast(ot_names[0]),
            .mon2_ot_name = @bitCast(ot_names[1]),
            .mon3_ot_name = @bitCast(ot_names[2]),
            .mon4_ot_name = @bitCast(ot_names[3]),
            .mon5_ot_name = @bitCast(ot_names[4]),
            .mon6_ot_name = @bitCast(ot_names[5]),
            .mon1_name = @bitCast(mon_names[0]),
            .mon2_name = @bitCast(mon_names[1]),
            .mon3_name = @bitCast(mon_names[2]),
            .mon4_name = @bitCast(mon_names[3]),
            .mon5_name = @bitCast(mon_names[4]),
            .mon6_name = @bitCast(mon_names[5]),
        };
    }
};

fn moveFromId(move_number: u8) ?*const moves_ns.Move{
    if (move_number > 0) {
        return &moves_ns.moves[move_number - 1];
    } else {
        return null;
    }
}

pub const MonBox = struct {
    box_number: u8,
    number_of_mon: u8,
    mons: [20]Mon,

    pub fn init(fullBoxData: gen2data.FullBoxData, box_number: u8, allocator: std.mem.Allocator) @This(){
        var mons: [20]Mon = std.mem.zeroes([20]Mon);
        var i: usize = 0;
        var number_of_mon = fullBoxData.number_of_mon;
        if (number_of_mon == 255) {
            number_of_mon = 0;
        }

        while (i < number_of_mon): (i += 1) {
            const mon = Mon.fromStrippedMonData(fullBoxData.mon[i], fullBoxData.mon_names[i],  fullBoxData.ot_names[i], allocator);
            mons[i] = mon;
        }
        return .{
            .box_number = box_number,
            .number_of_mon = number_of_mon,
            .mons = mons
        };
    }

    pub fn toFullBoxData(self: *const @This()) gen2data.FullBoxData {
        var species: [box_size]u8 = undefined;
        var ot_names: [box_size][11]u8 = undefined;
        var mon_names: [box_size][11]u8 = undefined;
        var mons: [box_size]gen2data.StrippedMonData = undefined;

        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            species[i] = self.mons[i].base_data.dex_number;
            ot_names[i] = encoding.utf8ToGen2(self.mons[i].base_data.ot_name);
            mon_names[i] = encoding.utf8ToGen2(self.mons[i].base_data.name);
            mons[i] = self.mons[i].toStrippedMonData();
        }
        while (i < box_size): (i += 1) {
            species[i] = 255;
            ot_names[i] = .{80} ** 11;
            mon_names[i] = .{80} ** 11;
        }

        return .{
            .number_of_mon = self.number_of_mon,
            .species_id = species,
            .padding0 = 255,
            .mon = mons,
            .ot_names = ot_names,
            .mon_names = mon_names,
            .padding1 = .{255, 255},
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
};

pub const MonBaseData = struct {
    dex_number: u8,
    name: []const u8,
    level: u8,
    held_item: u8,
    moves: [4]?*const moves_ns.Move,
    ot_number: u16,
    ot_name: []const u8,
    experience_points: u24,
    evs: EV,
    ivs: IV,
    move_pps: [4]MonPP,
    friendship_eggcycles: u8,
    pokerus: u8,
    caught_data: u16,

    fn init(mon_data: gen2data.StrippedMonData, mon_name: [11]u8, ot_name: [11]u8, allocator: std.mem.Allocator) @This() {
        return MonBaseData{
            .dex_number = mon_data.index_number,
            .name = encoding.gen2toUtf8(mon_name[0..], allocator) catch {unreachable;},
            .level = mon_data.level,
            .held_item = mon_data.held_item_number,
            .moves = .{moveFromId(mon_data.move_1), moveFromId(mon_data.move_2), moveFromId(mon_data.move_3), moveFromId(mon_data.move_4)},
            .ot_number = @byteSwap(mon_data.ot_number),
            .ot_name = encoding.gen2toUtf8(ot_name[0..], allocator) catch {unreachable;},
            .experience_points = @byteSwap(mon_data.experience_points),
            .evs = .{
                .hp = @byteSwap(mon_data.hp_ev),
                .attack = @byteSwap(mon_data.attack_ev),
                .defense = @byteSwap(mon_data.defense_ev),
                .speed = @byteSwap(mon_data.speed_ev),
                .special = @byteSwap(mon_data.special_ev),
            },
            .ivs = .{
                .attack = mon_data.iv_attack,
                .defense = mon_data.iv_defense,
                .speed = mon_data.iv_speed,
                .special = mon_data.iv_special
            },
            .move_pps = .{MonPP.init(mon_data.pp_1), MonPP.init(mon_data.pp_2), MonPP.init(mon_data.pp_3), MonPP.init(mon_data.pp_4)},
            .friendship_eggcycles = mon_data.friendship_eggcycles,
            .pokerus = mon_data.pokerus,
            .caught_data = @byteSwap(mon_data.caught_data)
        };
    }
};


fn calculate_hp(iv: IV, ev: u16, level: u8, dex_number: u8) u16 {
    const calculated_iv = ((iv.attack & 1) << 3) + ((iv.defense & 1) << 2) + ((iv.speed & 1) << 1) + (iv.special & 1);
    const base_stat = gen2_species_data[dex_number - 1].base_hp;
    return (((((base_stat + calculated_iv) * 2) + (@as(u16, @intFromFloat(std.math.sqrt(@as(f64, @floatFromInt(ev)))/4.0)))) * level)/100) + level + 10;
}

const StatType = enum {
    ATTACK,
    DEFENSE,
    SPEED,
    SPECIAL_ATTACK,
    SPECIAL_DEFENSE
};

fn calculate_other_stat(iv: u8, ev: u16, level: u8, dex_number: u8, stat_type: StatType) u16 {
    const species = gen2_species_data[dex_number - 1];
    const base_stat = switch (stat_type) {
        .ATTACK => species.base_attack,
        .DEFENSE => species.base_defense,
        .SPEED => species.base_speed,
        .SPECIAL_ATTACK => species.base_special_attack,
        .SPECIAL_DEFENSE => species.base_special_defense
    };

    return (((((base_stat + iv) * 2) + (@as(u16,@intFromFloat(std.math.sqrt(@as(f64, @floatFromInt(ev)))/4.0)))) * level)/100) + 5;
}

pub const Stats = struct {
    statuses: Statuses,
    current_hp: u16,
    max_hp: u16,
    attack: u16,
    defense: u16,
    speed: u16,
    special_attack: u16,
    special_defense: u16,

    pub fn fromMonBaseData(mon_data: MonBaseData) @This() {
        const max_hp = calculate_hp(mon_data.ivs, mon_data.evs.hp, mon_data.level, mon_data.dex_number);

        return .{
            .statuses = .{
                .asleep = false,
                .burned = false,
                .frozen = false,
                .paralyzed = false,
                .poisoned = false
            },
            .current_hp = max_hp,
            .max_hp = max_hp,
            .attack = calculate_other_stat(mon_data.ivs.attack, mon_data.evs.attack, mon_data.level, mon_data.dex_number, .ATTACK),
            .defense = calculate_other_stat(mon_data.ivs.defense, mon_data.evs.defense, mon_data.level, mon_data.dex_number, .DEFENSE),
            .speed = calculate_other_stat(mon_data.ivs.speed, mon_data.evs.speed, mon_data.level, mon_data.dex_number, .SPEED),
            .special_attack = calculate_other_stat(mon_data.ivs.special, mon_data.evs.special, mon_data.level, mon_data.dex_number, .SPECIAL_ATTACK),
            .special_defense = calculate_other_stat(mon_data.ivs.special, mon_data.evs.special, mon_data.level, mon_data.dex_number, .SPECIAL_DEFENSE),
        };
    }
};

pub const MonSpecies = extern struct {
    dex_number: u8,
    base_hp: u8,
    base_attack: u8,
    base_defense: u8,
    base_speed: u8,
    base_special_attack: u8,
    base_special_defense: u8,
    type1: u8,
    type2: u8,
    catch_rate: u8,
    base_exp_yield: u8,
    wild_item_1: u8,
    wild_item_2: u8,
    gender_ratio: u8,
    egg_cycles: u8,
    front_sprite_dimensions: u8,
    growth_rate: u8,
    egg_groups: u8,
    tm_hm_flags: [8]u8
};

pub const CaughtMon = struct {
    current_box: u8,
    party: MonParty,
    boxes: [number_of_boxes]MonBox,
    move_mon: interface.MoveMon,

    pub fn init(input: []const u8, allocator: std.mem.Allocator) @This() {
        const current_box: u8 = input[gen2data.current_box_number];
        const temp_box_data = gen2data.FullBoxData.init(input[gen2data.current_box_start..gen2data.current_box_start + gen2data.box_size]);
        const party_data: gen2data.FullPartyData = @bitCast(input[gen2data.party_start .. gen2data.party_start + gen2data.party_size][0..gen2data.party_size].*);
        const party = MonParty.init(party_data, allocator);

        var boxes: [14]MonBox = undefined;
        boxes[current_box] = MonBox.init(temp_box_data, current_box + 1, allocator);
        var j: usize = 0;
        while (j < 14): (j += 1) {
             if (j != current_box) {
                 const box_start: usize = gen2data.boxes_start + (gen2data.box_size*j);
                 const box_end: usize = box_start + gen2data.box_size;
                 const full_box_data: gen2data.FullBoxData = gen2data.FullBoxData.init(input[box_start..box_end][0..gen2data.box_size]);

                 boxes[j] = MonBox.init(full_box_data, @intCast(j + 1), allocator);
             }
        }

        return .{
            .current_box = current_box,
            .party = party,
            .boxes = boxes,
            .move_mon = interface.MoveMon.init(party_size, box_size, number_of_boxes, allocator)
        };
    }

    pub fn printSummary(self: *const @This()) void {
        pok_transfer.bufferedPrint("Current box: {d}\nParty size: {d}\nBox 1 size: {d:<5}Box 2 size: {d:<5}Box 3 size: {d:<5}Box 4 size: {d:<5}\nBox 5 size: {d:<5}Box 6 size: {d:<5}Box 7 size: {d:<5}Box 8 size: {d:<5}\nBox 9 size: {d:<5}Box 10 size: {d:<4}Box 11 size: {d:<4}Box 12 size: {d:<4}\nBox 13 size: {d:<4}Box 14 size: {d:<4}",
            .{self.current_box + 1, self.party.number_of_mon,
                self.boxes[0].number_of_mon, self.boxes[1].number_of_mon, self.boxes[2].number_of_mon, self.boxes[3].number_of_mon,
                self.boxes[4].number_of_mon, self.boxes[5].number_of_mon, self.boxes[6].number_of_mon, self.boxes[7].number_of_mon,
                self.boxes[8].number_of_mon, self.boxes[9].number_of_mon, self.boxes[10].number_of_mon, self.boxes[11].number_of_mon,
                self.boxes[12].number_of_mon, self.boxes[13].number_of_mon
            });
    }

    pub fn markForTransfer(self: *@This(), box: ?u8, mon: u8) void {
        if (box != null) {
            self.move_mon.box_mon[box.?][mon] = true;
        } else {
            self.move_mon.party_mon[mon] = true;
        }
    }

    pub fn unmarkForTransfer(self: *@This(), box: ?u8, mon: u8) void {
        if (box != null) {
            self.move_mon.box_mon[box.?][mon] = false;
        } else {
            self.move_mon.party_mon[mon] = false;
        }
    }

    pub fn getMon(self: *@This(), box: ?u8, mon: u8) Mon {
        if (box != null) {
            return self.boxes[box.?].mons[mon];
        } else {
            return self.party.mons[mon];
        }
    }

    pub fn getVersion(self: *@This()) versions.Version {
        _ = self;
        return versions.Version.GEN2GS;
    }

    pub fn toSave(self: *const @This(), save_bytes: *[gen2data.save_size]u8 ) void {
        const full_party_data = self.party.toFullPartyData();
        const full_party_bytes: [gen2data.party_size]u8 = @bitCast(full_party_data);
        std.mem.copyForwards(u8, save_bytes[gen2data.party_start .. gen2data.party_start + gen2data.party_size], full_party_bytes[0..]);

        const current_box = self.boxes[self.current_box];
        const current_box_data = current_box.toFullBoxData().toFullBoxDataByteArray();
        std.mem.copyForwards(u8, save_bytes[gen2data.current_box_start..gen2data.current_box_start + gen2data.box_size], current_box_data[0..]);

        var i: usize = 0;
        while (i < number_of_boxes): ( i += 1) {
            const box_data = self.boxes[i].toFullBoxData().toFullBoxDataByteArray();
            const box_start = gen2data.boxes_start + (i * gen2data.box_size);
            const box_end = box_start + gen2data.box_size;
            std.mem.copyForwards(u8, save_bytes[box_start .. box_end], box_data[0..]);
        }

        gen2data.set_checksum(save_bytes);
    }

    pub fn insertMon(self: *@This(), mon: interface.MonInterface) !void{
        var i: usize = 0;
        const mon_insert = try Mon.fromMonInterface(mon);
        while(i < 12): (i += 1) {
            if (self.boxes[i].number_of_mon < 20) {
                self.boxes[i].mons[self.boxes[i].number_of_mon] = mon_insert;
                self.boxes[i].number_of_mon += 1;
                return;
            }
        }
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

    pub fn getFreeSpace(self: @This()) u16 {
        var free: u16 = number_of_boxes*box_size;
        for (self.boxes) |box| {
            free -= (box_size - box.number_of_mon);
        }
        return free;
    }

};