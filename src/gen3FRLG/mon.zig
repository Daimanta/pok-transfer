const std = @import("std");

pub const MiscFlags = packed struct {
    bad_egg: bool,
    has_species: bool,
    use_egg_name: bool,
    block_box_rs: bool
};

pub const ContestStats = struct {
    coolness: u8,
    beauty: u8,
    cuteness: u8,
    smartness: u8,
    toughness: u8,
    feel: u8
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

pub const MonBaseData = struct {
    personality_value: u32,
    ot_id: u32,
    nickname: []u8,
    language: u8,
    misc_flags: u8,
    ot_name: []u8,
    markings: u8,
    checksum: u16,
    unknown0: u16,
    dex_number: u16,
    item_held: u16,
    experience: u32,
    pp_bonuses: u8,
    friendship: u8,
    moves: [4]u16,
    pps: [4]u8,
    contest_stats: ContestStats,
    pokerus: u8,
    met_location: u8,
    origins_info: u16,
    iv_egg_ability: u32,
    ribbons_obedience: u32,
};

pub const Stats = struct {
    status_condition: u32,
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
};