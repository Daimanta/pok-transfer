const std = @import("std");
const gen1data = @import("save_datastructure.zig");
const encoding = @import("encoding.zig");
const moves_ns = @import("../general/moves.zig");
const pok_transfer = @import("../root.zig");
const StringBuilder = @import("../util/strings.zig").StringBuilder;
const interface = @import("../general/interface.zig");
const versions = @import("../general/versions.zig");
const gen2 = @import("../gen2GS/mon.zig");
const gen3 = @import("../gen3FRLG/mon.zig");

pub const box_size = 20;
pub const number_of_boxes = 12;
pub const party_size = 6;

pub const save_size = gen1data.save_size;

const gen1_species_data = std.mem.bytesAsValue([151]MonSpecies, @embedFile("species.dat"));

pub const MonType = enum {
    NORMAL,
    FIGHTING,
    FLYING,
    POISON,
    GROUND,
    ROCK,
    BIRD,
    BUG,
    GHOST,
    FIRE,
    WATER,
    GRASS,
    ELECTRIC,
    PSYCHIC,
    ICE,
    DRAGON
};

pub const MonPP = struct {
    applied_pp_up: u2,
    current_pp: u6,

    pub fn toGen1Number(self: @This()) u8 {
        return self.current_pp | @as(u8, self.applied_pp_up) << 6;
    }

    pub fn toMonPP(self: @This()) gen1data.MonPP {
        return .{
            .applied_ppup = self.applied_pp_up,
            .current_pp = self.current_pp
        };
    }

    fn fromGen2(pps: [4]gen2.MonPP) [4]MonPP {
        var result: [4]MonPP = undefined;
        var i: usize = 0;
        while (i < result.len): (i+=1) {
            result[i] = .{
                .current_pp = pps[i].current_pp,
                .applied_pp_up = pps[i].applied_pp_up
            };
        }
        return result;
    }

    fn fromGen3(pp_vals: [4]u8, pp_bonuses: [4]u2) [4]MonPP {
        var result: [4]MonPP = undefined;
        var i: usize = 0;
        while (i < result.len): (i+=1) {
            result[i] = .{
                .current_pp = @intCast(pp_vals[i]),
                .applied_pp_up = pp_bonuses[i]
            };
        }
        return result;
    }
};

pub const Statuses = struct {
    asleep: bool,
    poisoned: bool,
    burned: bool,
    frozen: bool,
    paralyzed: bool,
    
    pub fn toNumber(self: @This()) u8 {
        return @as(u8, @intFromBool(self.asleep)) << 2 | @as(u8, @intFromBool(self.poisoned)) << 3 | @as(u8, @intFromBool(self.burned)) << 4 | @as(u8, @intFromBool(self.frozen)) << 5 | @as(u8, @intFromBool(self.paralyzed)) << 6;
    }
};

pub const EV = struct {
    hp: u16,
    attack: u16,
    defense: u16,
    speed: u16,
    special: u16,

    fn fromGen2(ev: gen2.EV) @This() {
        return .{
            .hp = ev.hp,
            .attack = ev.attack,
            .defense = ev.defense,
            .speed = ev.speed,
            .special = ev.special
        };
    }

    fn fromGen3(ev: gen3.EV) @This() {
        return .{
            .hp = @as(u16, ev.hp) * 256,
            .attack = @as(u16, ev.attack) * 256,
            .defense = @as(u16, ev.defense) * 256,
            .speed = @as(u16, ev.speed) * 256,
            .special = @as(u16, ev.special_attack) * 256
        };
    }
};

pub const IV = struct {
    attack: u4,
    defense: u4,
    speed: u4,
    special: u4,

    fn fromGen2(iv: gen2.IV) @This() {
        return .{
            .attack = iv.attack,
            .defense = iv.defense,
            .speed = iv.speed,
            .special = iv.special
        };
    }

    fn fromGen3(iv: gen3.Ability) @This() {
        return .{
            .attack = @intCast(iv.attack_iv / 2),
            .defense = @intCast(iv.defense_iv / 2),
            .speed = @intCast(iv.speed_iv / 2),
            .special = @intCast(iv.special_attack_iv / 2)
        };
    }
};

pub const Stats = struct {
    max_hp: u16,
    attack: u16,
    defense: u16,
    speed: u16,
    special: u16,

    fn fromBaseData(base_data: MonBaseData) @This() {
        return .{
            .max_hp = calculate_hp(base_data.ivs, base_data.evs.hp, base_data.level, base_data.dex_number),
            .attack = calculate_other_stat(base_data.ivs.attack, base_data.evs.attack, base_data.level, base_data.dex_number, .ATTACK),
            .defense = calculate_other_stat(base_data.ivs.defense, base_data.evs.defense, base_data.level, base_data.dex_number, .DEFENSE),
            .speed = calculate_other_stat(base_data.ivs.speed, base_data.evs.speed, base_data.level, base_data.dex_number, .SPEED),
            .special = calculate_other_stat(base_data.ivs.special, base_data.evs.special, base_data.level, base_data.dex_number, .SPECIAL)
        };
    }
};

pub const MonBaseData = struct {
    dex_number: u8,
    name: []const u8,
    current_hp: u16,
    level: u8,
    statuses: Statuses,
    type1: u8,
    type2: u8,
    held_item: u8,
    moves: [4]?*const moves_ns.Move,
    ot_number: u16,
    ot_name: []const u8,
    experience_points: u24,
    evs: EV,
    ivs: IV,
    move_pps: [4]MonPP,

    pub fn init(gen1mon: gen1data.StrippedMonData, gen1name: [11]u8, ot_name: [11]u8, allocator: std.mem.Allocator) @This() {
        return .{
            .dex_number = gen1data.toNationalDexNumber(gen1mon.index_number),
            .name = encoding.genItoUtf8(gen1name[0..], allocator) catch {std.process.exit(1);},
            .current_hp = @byteSwap(gen1mon.hp),
            .level = gen1mon.level_repr,
            .statuses = .{
                .asleep = gen1mon.status_condition & 4 != 0,
                .poisoned = gen1mon.status_condition & 8 != 0,
                .burned = gen1mon.status_condition & 16 != 0,
                .frozen = gen1mon.status_condition & 32 != 0,
                .paralyzed = gen1mon.status_condition & 64 != 0,
            },
            .type1 = gen1mon.type1,
            .type2 = gen1mon.type2,
            .held_item = gen1mon.catch_rate_held_item,
            .moves = .{moveFromId(gen1mon.move_1), moveFromId(gen1mon.move_2), moveFromId(gen1mon.move_3), moveFromId(gen1mon.move_4)},
            .ot_number = @byteSwap(gen1mon.original_trainer_number),
            .ot_name = encoding.genItoUtf8(ot_name[0..], allocator) catch {std.process.exit(1);},
            .experience_points = @byteSwap(gen1mon.experience_points),
            .evs = .{
                .hp = @byteSwap(gen1mon.hp_ev),
                .attack = @byteSwap(gen1mon.attack_ev),
                .defense = @byteSwap(gen1mon.defense_ev),
                .speed = @byteSwap(gen1mon.speed_ev),
                .special = @byteSwap(gen1mon.special_ev),
            },
            .ivs = .{
                .attack = gen1mon.iv_1,
                .defense = gen1mon.iv_2,
                .speed = gen1mon.iv_3,
                .special = gen1mon.iv_4,
            },
            .move_pps = .{
                .{.applied_pp_up = gen1mon.pp_1.applied_ppup, .current_pp = gen1mon.pp_1.current_pp},
                .{.applied_pp_up = gen1mon.pp_2.applied_ppup, .current_pp = gen1mon.pp_2.current_pp},
                .{.applied_pp_up = gen1mon.pp_3.applied_ppup, .current_pp = gen1mon.pp_3.current_pp},
                .{.applied_pp_up = gen1mon.pp_4.applied_ppup, .current_pp = gen1mon.pp_4.current_pp}
            },
        };
    }
};

pub const Mon = struct {
    base_data: MonBaseData,
    stats: Stats,

    pub fn printShortSummary(self: @This()) void {
        pok_transfer.bufferedPrint("{s}, lvl. {d} {s}\n", .{self.base_data.name, self.base_data.level, @import("../general/names.zig").mon_names[self.base_data.dex_number - 1]});
    }

    pub fn printFullSummary(self: @This()) void {
        const type_name = @import("../general/names.zig").mon_names[self.base_data.dex_number - 1];
        var condition:[]const u8 = "-";
        if (self.base_data.statuses.asleep) {
            condition = "ASLEEP";
        } else if (self.base_data.statuses.poisoned) {
            condition = "POISONED";
        } else if (self.base_data.statuses.burned) {
            condition = "BURNED";
        } else if (self.base_data.statuses.frozen) {
            condition = "FROZEN";
        } else if (self.base_data.statuses.paralyzed) {
            condition = "PARALYZED";
        }
        const shiny_string = if (self.isShiny()) "*" else "";

        pok_transfer.bufferedPrint("{s}, lvl. {d} {s} {s} {s}", .{self.base_data.name, self.base_data.level, type_name, self.getGenderSymbol(), shiny_string});
        if (self.base_data.type1 != self.base_data.type2) {
            pok_transfer.bufferedPrint("({s}/{s})", .{@tagName(typeFromGen1Mon(self.base_data.type1)), @tagName(typeFromGen1Mon(self.base_data.type2))});
        } else {
            pok_transfer.bufferedPrint("({s})", .{@tagName(typeFromGen1Mon(self.base_data.type1))});
        }

        const hp_exp = "HP: {d}/{d} Exp: {d}";
        const ot = "OT: {s} ({d})";
        const moves_str = "Move 1: {s} Move 2: {s}\nMove 3: {s} Move 4: {s}";
        const stats = "HP: {d} Attack: {d} Defense: {d} Speed: {d} Special: {d}";
        const ivs = "Attack IV: {d} Defense IV: {d} Speed IV: {d} Special IV: {d}";
        const evs = "HP EV: {d} Attack EV: {d} Defense EV: {d} Speed EV: {d} Special EV: {d}";

        const iv_obj = self.base_data.ivs;
        const ev_obj = self.base_data.evs;

        const move1_str = if (self.base_data.moves[0] != null) self.base_data.moves[0].?.name else "-";
        const move2_str = if (self.base_data.moves[1] != null) self.base_data.moves[1].?.name else "-";
        const move3_str = if (self.base_data.moves[2] != null) self.base_data.moves[2].?.name else "-";
        const move4_str = if (self.base_data.moves[3] != null) self.base_data.moves[3].?.name else "-";

        pok_transfer.bufferedPrint( "\n" ++ hp_exp ++ "\n" ++ ot ++ "\n" ++ moves_str ++ "\n" ++ stats ++ "\n" ++ ivs ++ "\n" ++ evs, .{
            self.base_data.current_hp, self.stats.max_hp, self.base_data.experience_points, self.base_data.ot_name, self.base_data.ot_number,
            move1_str, move2_str, move3_str, move4_str,
            self.stats.max_hp, self.stats.attack, self.stats.defense, self.stats.speed, self.stats.special,
            iv_obj.attack, iv_obj.defense, iv_obj.speed, iv_obj.special,
            ev_obj.hp, ev_obj.attack, ev_obj.defense, ev_obj.speed, ev_obj.special
        });
    }

    pub fn toMonData(self: @This()) gen1data.MonData{
        return .{
            .strippedMonData = toStrippedMonData(self),
            .level = self.base_data.level,
            .max_hp = @byteSwap(self.stats.max_hp),
            .attack = @byteSwap(self.stats.attack),
            .defense = @byteSwap(self.stats.defense),
            .speed = @byteSwap(self.stats.speed),
            .special = @byteSwap(self.stats.special)
        };
    }

    pub fn toStrippedMonData(self: @This()) gen1data.StrippedMonData {
        return .{
            .index_number = gen1data.gen1NumberFromNationalDexNumber(self.base_data.dex_number),
            .hp = @byteSwap(self.base_data.current_hp),
            .level_repr = self.base_data.level,
            .status_condition = self.base_data.statuses.toNumber(),
            .type1 = self.base_data.type1,
            .type2 = self.base_data.type2,
            .catch_rate_held_item = self.base_data.held_item,
            .move_1 = if (self.base_data.moves[0] != null) @intCast(self.base_data.moves[0].?.id) else 0,
            .move_2 = if (self.base_data.moves[1] != null) @intCast(self.base_data.moves[1].?.id) else 0,
            .move_3 = if (self.base_data.moves[2] != null) @intCast(self.base_data.moves[2].?.id) else 0,
            .move_4 = if (self.base_data.moves[3] != null) @intCast(self.base_data.moves[3].?.id) else 0,
            .original_trainer_number = @byteSwap(self.base_data.ot_number),
            .experience_points = @byteSwap(self.base_data.experience_points),
            .hp_ev = @byteSwap(self.base_data.evs.hp),
            .attack_ev = @byteSwap(self.base_data.evs.attack),
            .defense_ev = @byteSwap(self.base_data.evs.defense),
            .speed_ev = @byteSwap(self.base_data.evs.speed),
            .special_ev = @byteSwap(self.base_data.evs.special),
            .iv_1 = self.base_data.ivs.attack,
            .iv_2 = self.base_data.ivs.defense,
            .iv_3 = self.base_data.ivs.speed,
            .iv_4 = self.base_data.ivs.special,
            .pp_1 = self.base_data.move_pps[0].toMonPP(),
            .pp_2 = self.base_data.move_pps[1].toMonPP(),
            .pp_3 = self.base_data.move_pps[2].toMonPP(),
            .pp_4 = self.base_data.move_pps[3].toMonPP(),
        };
    }

    // Not actually used in Gen 1 but it does indicate the gender in later generations
    pub fn getGender(self: @This()) interface.Gender {
        const species = gen2.gen2_species_data[self.base_data.dex_number - 1];
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

    // Shinyness is shared with Gen 2
    pub fn isShiny(self: @This()) bool {
        if (self.base_data.ivs.defense != 10 or self.base_data.ivs.speed != 10 or self.base_data.ivs.special != 10) {
            return false;
        }
        const matches: []const u8 = &[_]u8{2, 3, 6, 7, 10, 11, 14, 15};
        for (matches) |match| {
            if (self.base_data.ivs.attack == match) {
                return true;
            }
        }
        return false;
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
};

pub const MonSpecies = extern struct {
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
    tm_hm_flags: [7]u8,
};

pub const MonReference = struct {
    party: bool,
    box_number: u8,
    index_number: u8
};

pub const MoveMon = struct {
    party_mon: [6]bool,
    box_mon: [12][20]bool,

    pub fn init() @This() {
        return .{
            .party_mon = .{false} ** 6,
            .box_mon = .{.{ false } ** box_size} ** number_of_boxes
        };
    }

    pub fn getNumberOfMoves(self: @This()) u8 {
        var number_of_moves: u8 = 0;
        for (self.party_mon) |mon| {
            if (mon) {
                number_of_moves += 1;
            }
        }
        for (self.box_mon) |box| {
            for (box) |mon| {
                if (mon) {
                    number_of_moves += 1;
                }
            }
        }
        return number_of_moves;
    }
};

pub const CaughtMon = struct {
    current_box: u8,
    has_changed: bool,
    party: MonParty,
    boxes: [12]MonBox,
    move_mon: interface.MoveMon,

    pub fn init(input: []const u8, allocator: std.mem.Allocator) @This() {
        const current_box: u16 = input[gen1data.current_box_start] + (@as(u16, input[gen1data.current_box_start + 1]) << 8);
        const has_changed = current_box > 127;
        const current_box_number: u8 = @intCast(current_box & 127);

        const temp_box_data = gen1data.FullBoxData.init(input[gen1data.box_copy..gen1data.box_copy + gen1data.box_size].*);
        const party_data: gen1data.FullPartyData = @bitCast(input[gen1data.party .. gen1data.party + gen1data.party_size][0..gen1data.party_size].*);
        const party = MonParty.init(party_data, allocator);

        var boxes: [12]MonBox = undefined;
        boxes[current_box_number] = MonBox.init(temp_box_data, current_box_number + 1, allocator);
        var j: usize = 0;
        while (j < gen1data.box_starts.len): (j += 1) {
            if (j != current_box_number) {
                const box_start: usize = gen1data.box_starts[j];
                const box_data = gen1data.FullBoxData.init(input[box_start..box_start + gen1data.box_size][0..gen1data.box_size].*);
                boxes[j] = MonBox.init(box_data, @intCast(j + 1), allocator);
            }
        }

        return .{
            .current_box = current_box_number,
            .has_changed = has_changed,
            .party = party,
            .boxes = boxes,
            .move_mon = interface.MoveMon.init(party_size, box_size, number_of_boxes, allocator)
        };
    }

    pub fn printSummary(self: *const @This()) void {
        pok_transfer.bufferedPrint("Has ever changed boxes: {any}\nCurrent box: {d}\nParty size: {d}\nBox 1 size: {d:<5}Box 2 size: {d:<5}Box 3 size: {d:<5}Box 4 size: {d:<5}\nBox 5 size: {d:<5}Box 6 size: {d:<5}Box 7 size: {d:<5}Box 8 size: {d:<5}\nBox 9 size: {d:<5}Box 10 size: {d:<4}Box 11 size: {d:<4}Box 12 size: {d:<4}\n",
            .{self.has_changed, self.current_box + 1, self.party.number_of_mon, self.boxes[0].number_of_mon, self.boxes[1].number_of_mon, self.boxes[2].number_of_mon, self.boxes[3].number_of_mon, self.boxes[4].number_of_mon, self.boxes[5].number_of_mon, self.boxes[6].number_of_mon, self.boxes[7].number_of_mon, self.boxes[8].number_of_mon, self.boxes[9].number_of_mon, self.boxes[10].number_of_mon, self.boxes[11].number_of_mon});
    }

    pub fn copyToOtherSave(source: *@This(), destination: *@This(), reference: MonReference) !void {
        var mon: Mon = undefined;
        if (!destination.has_changed) {
            return error.BoxesWereNeverChanged;
        }
        if (reference.party) {
            if (reference.index_number + 1 > source.party.number_of_mon) {
                return error.IndexOutOfBounds;
            }
            mon = source.party.mons[reference.index_number];
        } else {
            if (reference.box_number >= 12) {
                return error.IncorrectBoxNumber;
            }
            if (reference.index_number + 1 > source.boxes[reference.box_number].number_of_mon) {
                return error.IndexOutOfBounds;
            }
            mon = source.boxes[reference.box_number].mons[reference.index_number];
        }
        var i: usize = 0;
        while(i < 12): (i += 1) {
            if (destination.boxes[i].number_of_mon < 20) {
                destination.boxes[i].mons[destination.boxes[i].number_of_mon] = mon;
                destination.boxes[i].number_of_mon += 1;
                return;
            }
        }
        return error.DestinationOutOfSpace;
    }

    pub fn insertMon(self: *@This(), mon: interface.MonInterface) !void {
        const gen1mon = try fromMonInterface(mon);
        var i: usize = 0;
        while(i < 12): (i += 1) {
            if (self.boxes[i].number_of_mon < 20) {
                self.boxes[i].mons[self.boxes[i].number_of_mon] = gen1mon;
                self.boxes[i].number_of_mon += 1;
                return;
            }
        }
    }

    pub fn removeMon(self: *@This(), box: ?u8, mon: u8) void {
        if (box == null) {
            _ = removeMonFromParty(self, mon);
        } else {
            _ = removeMonFromBox(self, box.?, mon);
        }
    }


    fn fromMonInterface(mon_interface: interface.MonInterface) !Mon {
        const result = switch (mon_interface) {
            .gen1 => mon_interface.gen1,
            .gen2gs => fromGen2(mon_interface.gen2gs),
            .gen3frlg => fromGen3(mon_interface.gen3frlg),
        };
        return result;
    }

    fn fromGen2(gen2_mon: gen2.Mon) !Mon {
        if (gen2_mon.base_data.dex_number > 151) return error.GenerationTooHigh;
        if (gen2_mon.base_data.held_item > 0) return error.MonHasHeldItem;
        for (gen2_mon.base_data.moves) |mmove|{
            if (mmove != null and mmove.?.generation > 1) {
                return error.MoveGenerationTooHigh;
            }
        }

        const species_reference = gen1_species_data[gen2_mon.base_data.dex_number - 1];

        const base_data: MonBaseData = .{
            .dex_number = gen2_mon.base_data.dex_number,
            .name = gen2_mon.base_data.name,
            .current_hp = gen2_mon.stats.current_hp,
            .level = gen2_mon.base_data.level,
            .statuses = .{
                .asleep = gen2_mon.stats.statuses.asleep,
                .burned = gen2_mon.stats.statuses.burned,
                .frozen = gen2_mon.stats.statuses.frozen,
                .paralyzed = gen2_mon.stats.statuses.paralyzed,
                .poisoned = gen2_mon.stats.statuses.poisoned
            },
            .type1 = species_reference.type1,
            .type2 = species_reference.type2,
            .held_item = 0,
            .moves = gen2_mon.base_data.moves,
            .ot_number = gen2_mon.base_data.ot_number,
            .ot_name = gen2_mon.base_data.ot_name,
            .experience_points = gen2_mon.base_data.experience_points,
            .evs = EV.fromGen2(gen2_mon.base_data.evs),
            .ivs = IV.fromGen2(gen2_mon.base_data.ivs),
            .move_pps = MonPP.fromGen2(gen2_mon.base_data.move_pps),
        };
        return Mon{
            .base_data = base_data,
            .stats = Stats.fromBaseData(base_data)
        };

    }

    fn fromGen3(gen3_mon: gen3.Mon) !Mon {
        if (gen3_mon.base_data.dex_number > 151) return error.GenerationTooHigh;
        if (gen3_mon.base_data.item_held > 0) return error.MonHasHeldItem;
        for (gen3_mon.base_data.moves) |mmove|{
            if (mmove != null and mmove.?.generation > 1) {
                return error.MoveGenerationTooHigh;
            }
        }

        const species_reference = gen1_species_data[gen3_mon.base_data.dex_number - 1];

        const base_data: MonBaseData = .{
            .dex_number = @intCast(gen3_mon.base_data.dex_number),
            .name = gen3_mon.base_data.nickname,
            .current_hp = gen3_mon.stats.current_hp,
            .level = gen3_mon.stats.level,
            .statuses = .{
                .asleep = gen3_mon.stats.status_condition.sleep > 0,
                .burned = gen3_mon.stats.status_condition.burn,
                .frozen = gen3_mon.stats.status_condition.freeze,
                .paralyzed = gen3_mon.stats.status_condition.paralysis,
                .poisoned = gen3_mon.stats.status_condition.poison
            },
            .type1 = species_reference.type1,
            .type2 = species_reference.type2,
            .held_item = 0,
            .moves = gen3_mon.base_data.moves,
            .ot_number = @truncate(gen3_mon.base_data.ot_id),
            .ot_name = gen3_mon.base_data.ot_name,
            .experience_points = @truncate(gen3_mon.base_data.experience),
            .evs = EV.fromGen3(gen3_mon.base_data.ev),
            .ivs = IV.fromGen3(gen3_mon.base_data.iv_egg_ability),
            .move_pps = MonPP.fromGen3(gen3_mon.base_data.pps, gen3_mon.base_data.pp_bonuses),
        };
        return Mon{
            .base_data = base_data,
            .stats = Stats.fromBaseData(base_data)
        };
    }

    // Removes a mon from the party, will affect the indices of the mon after the removed mon
    fn removeMonFromParty(self: *@This(), index: u8) Mon {
        // Last mon can simply be ignored
        const result = self.party.mons[index];
        if (index != 5) {
            var i = index;
            while (i < 5): (i += 1) {
                self.party.mons[i] = self.party.mons[i + 1];
            }
        }
        self.party.number_of_mon -= 1;
        return result;
    }

    // Removes a mon from the specified box, will affect the indices of the mon after the removed mon
    fn removeMonFromBox(self: *@This(), box: u8, index: u8) Mon {
        // Last mon can simply be ignored
        const result = self.boxes[box].mons[index];
        if (index != 19) {
            var i = index;
            while (i < 19): (i += 1) {
                self.boxes[box].mons[i] = self.boxes[box].mons[i + 1];
            }
        }
        self.boxes[box].number_of_mon -= 1;
        return result;
    }

    pub fn getFreeSpace(self: @This()) u8 {
        var free: u8 = number_of_boxes*box_size;
        for (self.boxes) |box| {
            free -= (box_size - box.number_of_mon);
        }
        return free;
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
        return versions.Version.GEN1;
    }


    pub fn toSave(self: *@This(), save_bytes: *[gen1data.save_size]u8) void {
        const fullPartyData = self.party.toFullPartyData();
        const bytes: [gen1data.party_size]u8 = @bitCast(fullPartyData);
        std.mem.copyForwards(u8, save_bytes[gen1data.party .. gen1data.party + gen1data.party_size], bytes[0..]);

        const currentBoxData = self.boxes[self.current_box].toFullBoxData().toFullBoxDataByteArray();
        std.mem.copyForwards(u8, save_bytes[gen1data.box_copy..gen1data.box_copy + gen1data.box_size], @ptrCast(&currentBoxData));

        var i: usize = 0;
        while (i < self.boxes.len): (i += 1) {
            const fullBoxData = self.boxes[i].toFullBoxData().toFullBoxDataByteArray();
            const start = gen1data.box_starts[i];
            std.mem.copyForwards(u8, save_bytes[start..start + gen1data.box_size], @ptrCast(&fullBoxData));
        }

        gen1data.set_correct_checksums(save_bytes);
    }
};

pub const MonBox = struct {
    box_number: u8,
    number_of_mon: u8,
    mons: [20]Mon,

    pub fn init(fullBoxData: gen1data.FullBoxData, box_number: u8, allocator: std.mem.Allocator) @This(){
        var mons: [20]Mon = std.mem.zeroes([20]Mon);
        var i: usize = 0;
        while (i < fullBoxData.number_of_mon): (i += 1) {
            const base_mon = MonBaseData.init(fullBoxData.mon[i], fullBoxData.mon_names[i], fullBoxData.ot_names[i], allocator);
            const mon = monFromBaseData(base_mon);
            mons[i] = mon;
        }
        return .{
            .box_number = box_number,
            .number_of_mon = fullBoxData.number_of_mon,
            .mons = mons
        };
    }

    pub fn printSummary(self: @This()) void{
        pok_transfer.bufferedPrint("Box number: {d}\nNumber of mon: {d}\n", .{self.box_number, self.number_of_mon});
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            pok_transfer.bufferedPrint("{d}) ", .{i + 1});
            self.mons[i].printShortSummary();
        }
    }

    fn getSpeciesIds(self: @This()) [20]u8 {
        var result: [20]u8 = undefined;
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            result[i] = gen1data.gen1NumberFromNationalDexNumber(self.mons[i].base_data.dex_number);
        }

        while (i < 20): (i += 1) {
            result[i] = 255;
        }
        return result;
    }

    fn getMonNames(self: @This()) [20][11]u8 {
        var result: [20][11]u8 = undefined;

        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            result[i] = encoding.utf8ToGenI(self.mons[i].base_data.name);
        }

        while (i < 20): (i += 1) {
            result[i] = .{80} ** 11;
        }

        return result;
    }

    fn getOtNames(self: @This()) [20][11]u8 {
        var result: [20][11]u8 = undefined;

        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            result[i] = encoding.utf8ToGenI(self.mons[i].base_data.ot_name);
        }

        while (i < 20): (i += 1) {
            result[i] = .{80} ** 11;
        }

        return result;
    }

    fn getStrippedMons(self: @This()) [20]gen1data.StrippedMonData {
        var result: [20]gen1data.StrippedMonData = undefined;
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            result[i] = self.mons[i].toStrippedMonData();
        }

        while (i < 20): (i += 1) {
            result[i] = std.mem.zeroes(gen1data.StrippedMonData);
        }

        return result;
    }

    pub fn toFullBoxData(self: @This()) gen1data.FullBoxData {
        const result: gen1data.FullBoxData = .{
            .number_of_mon = self.number_of_mon,
            .species_id = self.getSpeciesIds(),
            .padding0 = 255,
            .mon = self.getStrippedMons(),
            .mon_names = self.getMonNames(),
            .ot_names = self.getOtNames()
        };
        return result;
    }
};

pub const MonParty = struct {
    number_of_mon: u8,
    mons: [6]Mon,

    pub fn init(party_data: gen1data.FullPartyData, allocator: std.mem.Allocator) @This() {
        var mons: [6]Mon = std.mem.zeroes([6]Mon);
        var i: usize = 0;
        const mon_data = party_data.getMons();
        const mon_names = party_data.getNames();
        const ot_names = party_data.getOtNames();

        while (i < party_data.number_of_mon): (i += 1) {
            mons[i] = monFromGen1Mon(mon_data[i], mon_names[i].toBytes(), ot_names[i].toBytes(), allocator);
        }

        return .{
            .number_of_mon = party_data.number_of_mon,
            .mons = mons
        };
    }

    pub fn printSummary(self: @This()) void{
        pok_transfer.bufferedPrint("Number of mon: {d}\n", .{self.number_of_mon});
        var i: usize = 0;
        while (i < self.number_of_mon): (i += 1) {
            pok_transfer.bufferedPrint("{d}) ", .{i + 1});
            self.mons[i].printShortSummary();
        }
    }

    pub fn toFullPartyData(self: @This()) gen1data.FullPartyData {
        var species: [6]u8 = undefined;
        var ot_names: [6][11]u8 = undefined;
        var mon_names: [6][11]u8 = undefined;
        var mons: [6]gen1data.MonData = undefined;

        var i: usize = 0;
        while (i < 6): (i += 1) {
            species[i] = if (self.number_of_mon >= i + 1) gen1data.gen1NumberFromNationalDexNumber(self.mons[i].base_data.dex_number) else 255;
        }
        i = 0;
        while (i < 6): (i += 1) {
            ot_names[i] = if (self.number_of_mon >= i + 1) encoding.utf8ToGenI(self.mons[i].base_data.ot_name) else .{80} ** 11;
        }
        i = 0;
        while (i < 6): (i += 1) {
            mon_names[i] = if (self.number_of_mon >= i + 1) encoding.utf8ToGenI(self.mons[i].base_data.name) else .{80} ** 11;
        }
        i = 0;
        while (i < 6): (i += 1) {
            mons[i] = if (self.number_of_mon >= i + 1) self.mons[i].toMonData() else std.mem.zeroes(gen1data.MonData);
        }

        const result: gen1data.FullPartyData = .{
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

        return result;
    }
};


fn calculate_hp(iv: IV, ev: u16, level: u8, dex_number: u8) u16 {
    const calculated_iv = ((iv.attack & 1) << 3) + ((iv.defense & 1) << 2) + ((iv.speed & 1) << 1) + (iv.special & 1);
    const base_stat = gen1_species_data[dex_number - 1].hp;
    return (((((base_stat + calculated_iv) * 2) + (@as(u16, @intFromFloat(std.math.sqrt(@as(f64, @floatFromInt(ev)))/4.0)))) * level)/100) + level + 10;
}

const StatType = enum {
    ATTACK,
    DEFENSE,
    SPEED,
    SPECIAL
};

fn calculate_other_stat(iv: u8, ev: u16, level: u8, dex_number: u8, stat_type: StatType) u16 {
    const species = gen1_species_data[dex_number - 1];
    const base_stat = switch (stat_type) {
        .ATTACK => species.attack,
        .DEFENSE => species.defense,
        .SPEED => species.speed,
        .SPECIAL => species.special
    };

    return (((((base_stat + iv) * 2) + (@as(u16,@intFromFloat(std.math.sqrt(@as(f64, @floatFromInt(ev)))/4.0)))) * level)/100) + 5;
}

pub fn monFromBaseData(baseData: MonBaseData) Mon {
    return .{
        .base_data = baseData,
        .stats = .{
            .max_hp = calculate_hp(baseData.ivs, baseData.evs.hp, baseData.level, baseData.dex_number),
            .attack = calculate_other_stat(baseData.ivs.attack, baseData.evs.attack, baseData.level, baseData.dex_number, .ATTACK),
            .defense = calculate_other_stat(baseData.ivs.defense, baseData.evs.defense, baseData.level, baseData.dex_number, .DEFENSE),
            .speed = calculate_other_stat(baseData.ivs.speed, baseData.evs.speed, baseData.level, baseData.dex_number, .SPEED),
            .special = calculate_other_stat(baseData.ivs.special, baseData.evs.special, baseData.level, baseData.dex_number, .SPECIAL)
        }
    };
}

fn moveFromId(move_number: u8) ?*const moves_ns.Move{
    if (move_number > 0) {
        return &moves_ns.moves[move_number - 1];
    } else {
        return null;
    }
}

pub fn monFromGen1Mon(gen1mon: gen1data.MonData, gen1name: [11]u8, ot_name: [11]u8, allocator: std.mem.Allocator) Mon {
    return .{
        .base_data = .{
            .dex_number = gen1data.toNationalDexNumber(gen1mon.strippedMonData.index_number),
            .name = encoding.genItoUtf8(gen1name[0..], allocator) catch {std.process.exit(1);},
            .current_hp = @byteSwap(gen1mon.strippedMonData.hp),
            .level = gen1mon.level,
            .statuses = .{
                .asleep = gen1mon.strippedMonData.status_condition & 4 != 0,
                .poisoned = gen1mon.strippedMonData.status_condition & 8 != 0,
                .burned = gen1mon.strippedMonData.status_condition & 16 != 0,
                .frozen = gen1mon.strippedMonData.status_condition & 32 != 0,
                .paralyzed = gen1mon.strippedMonData.status_condition & 64 != 0,
            },
            .type1 = gen1mon.strippedMonData.type1,
            .type2 = gen1mon.strippedMonData.type2,
            .held_item = gen1mon.strippedMonData.catch_rate_held_item,
            .moves = .{moveFromId(gen1mon.strippedMonData.move_1), moveFromId(gen1mon.strippedMonData.move_2), moveFromId(gen1mon.strippedMonData.move_3), moveFromId(gen1mon.strippedMonData.move_4)},
            .ot_number = @byteSwap(gen1mon.strippedMonData.original_trainer_number),
            .ot_name = encoding.genItoUtf8(ot_name[0..], allocator) catch {std.process.exit(1);},
            .experience_points = @byteSwap(gen1mon.strippedMonData.experience_points),
            .evs = .{
                .hp = @byteSwap(gen1mon.strippedMonData.hp_ev),
                .attack = @byteSwap(gen1mon.strippedMonData.attack_ev),
                .defense = @byteSwap(gen1mon.strippedMonData.defense_ev),
                .speed = @byteSwap(gen1mon.strippedMonData.speed_ev),
                .special = @byteSwap(gen1mon.strippedMonData.special_ev),
            },
            .ivs = .{
                .attack = gen1mon.strippedMonData.iv_1,
                .defense = gen1mon.strippedMonData.iv_2,
                .speed = gen1mon.strippedMonData.iv_3,
                .special = gen1mon.strippedMonData.iv_4,
            },
            .move_pps = .{
                .{.applied_pp_up = gen1mon.strippedMonData.pp_1.applied_ppup, .current_pp = gen1mon.strippedMonData.pp_1.current_pp},
                .{.applied_pp_up = gen1mon.strippedMonData.pp_2.applied_ppup, .current_pp = gen1mon.strippedMonData.pp_2.current_pp},
                .{.applied_pp_up = gen1mon.strippedMonData.pp_3.applied_ppup, .current_pp = gen1mon.strippedMonData.pp_3.current_pp},
                .{.applied_pp_up = gen1mon.strippedMonData.pp_4.applied_ppup, .current_pp = gen1mon.strippedMonData.pp_4.current_pp}
            },
        },
        .stats = .{
            .max_hp = @byteSwap(gen1mon.max_hp),
            .attack = @byteSwap(gen1mon.attack),
            .defense = @byteSwap(gen1mon.defense),
            .speed = @byteSwap(gen1mon.speed),
            .special = @byteSwap(gen1mon.special)
        },
    };
}

fn typeFromGen1Mon(typeNum: u8) MonType {
    return switch (typeNum) {
        0 => .NORMAL,
        1 => .FIGHTING,
        2 => .FLYING,
        3 => .POISON,
        4 => .GROUND,
        5 => .ROCK,
        6 => .BIRD,
        7 => .BUG,
        8 => .GHOST,
        20 => .FIRE,
        21 => .WATER,
        22 => .GRASS,
        23 => .ELECTRIC,
        24 => .PSYCHIC,
        25 => .ICE,
        26 => .DRAGON,
        else => .NORMAL
    };
}

