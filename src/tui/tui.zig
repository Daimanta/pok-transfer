const std = @import("std");
const builtin = @import("builtin");

const general = @import("../gen1/mon.zig");
const interface = @import("../general/interface.zig");

const pok_transfer = @import("../root.zig");

const eql = std.mem.eql;

pub const delimiter = switch (builtin.os.tag) {
    .linux => '\n',
    .windows => '\r',
    else => '\n'
};

pub const Mode = enum {
    GENERAL,
    PARTY,
    BOX,
    EXIT,
    PARTY_MON,
    BOX_MON
};

fn get_number(feedback: []const u8) ?u8 {
    const space_location = std.mem.indexOfScalar(u8, feedback, ' ');
    if (space_location == null or space_location.? == feedback.len - 1) {
        return null;
    }
    const rest = feedback[space_location.? + 1..];
    const box_number = std.fmt.parseInt(u8, rest, 10) catch {
        return null;
    };
    return box_number;
}

pub const State = struct {
    mode: Mode,
    box: u8,
    mon: u8,

    fn printRelevantMenu(self: @This(), caught: *interface.CaughtMonInterface) void {
        _ = caught;
        if (self.mode == .GENERAL) {
            pok_transfer.bufferedPrint("\na) Print summary of all mon\nb) Select party\nc <num>) Select box <num>\nx) Exit\nSelect option: ", .{});
        } else if (self.mode == .PARTY) {
            pok_transfer.bufferedPrint("\na) Print summary of all party mon\nb <num>) Select mon <num>\nc) Return to main menu\nx) Exit\nSelect option: ", .{});
        } else if (self.mode == .BOX) {
            pok_transfer.bufferedPrint("\nBox {d} selected\na) Print summary of all box mon\nb <num>) Select mon <num>\nc) Return to main menu\nx) Exit\nSelect option: ", .{self.box});
        } else if (self.mode == .PARTY_MON) {
            pok_transfer.bufferedPrint("\na) Print details of mon\nb) return to party\nc) Mark for transfer\nd) Unmark for transfer\nx) Exit\nSelect option: ", .{});
        } else if (self.mode == .BOX_MON) {
            pok_transfer.bufferedPrint("\na) Print details of mon\nb) return to box\nc) Mark for transfer\nd) Unmark for transfer\nx) Exit\nSelect option: ", .{});
        }
    }

    fn processGeneral(self: *@This(), feedback: []const u8, caught: *interface.CaughtMonInterface) void{
        if (eql(u8, "a", feedback)) {
            pok_transfer.bufferedPrint("\n", .{});
            caught.printSummary();
            pok_transfer.bufferedPrint("\n", .{});
        } else if (eql(u8, "b", feedback)) {
            self.mode = .PARTY;
        } else if (feedback[0] == 'c') {
            const box_number_opt = get_number(feedback);
            if (box_number_opt == null) {
                pok_transfer.bufferedPrint("Incorrect argument\n", .{});
                return;
            }
            const box_number = box_number_opt.?;
            if (box_number == 0 or box_number > 12) {
                pok_transfer.bufferedPrint("Incorrect argument\n", .{});
                return;
            }
            self.box = box_number;
            self.mode = .BOX;
        } else {
            pok_transfer.bufferedPrint("Incorrect argument\n", .{});
        }
    }

    fn processParty(self: *@This(), feedback: []const u8, caught: *interface.CaughtMonInterface) void {
        if (eql(u8, "a", feedback)) {
            pok_transfer.bufferedPrint("\n", .{});
            caught.printPartySummary();
            pok_transfer.bufferedPrint("\n", .{});
        } else if (feedback[0] == 'b') {
            const mon_number_opt = get_number(feedback);
            if (mon_number_opt == null) {
                pok_transfer.bufferedPrint("Incorrect argument\n", .{});
                return;
            }
            const mon_number = mon_number_opt.?;
            if (mon_number == 0 or mon_number > caught.getCurrentPartySize()) {
                pok_transfer.bufferedPrint("Incorrect argument\n", .{});
                return;
            }
            self.mode = .PARTY_MON;
            self.mon = mon_number;
        } else if (eql(u8, "c", feedback)) {
            self.mode = .GENERAL;
        } else {
            pok_transfer.bufferedPrint("Incorrect argument\n", .{});
        }
    }

    fn processBox(self: *@This(), feedback: []const u8, caught: *interface.CaughtMonInterface) void {
        const box_mon_count = caught.getCurrentBoxSize(self.box - 1);

        if (eql(u8, "a", feedback)) {
            pok_transfer.bufferedPrint("\n", .{});
            caught.printBoxSummary(self.box - 1);
            pok_transfer.bufferedPrint("\n", .{});
        } else if (feedback[0] == 'b') {
            const mon_number_opt = get_number(feedback);
            if (mon_number_opt == null) {
                pok_transfer.bufferedPrint("Incorrect argument\n", .{});
                return;
            }
            const mon_number = mon_number_opt.?;
            if (mon_number > box_mon_count) {
                pok_transfer.bufferedPrint("Incorrect argument\n", .{});
                return;
            }
            self.mode = .BOX_MON;
            self.mon = mon_number;
        } else if (eql(u8, "c", feedback)) {
            self.mode = .GENERAL;
        } else {
            pok_transfer.bufferedPrint("Incorrect argument\n", .{});
        }
    }

    fn processPartyMon(self: *@This(), feedback: []const u8, caught: *interface.CaughtMonInterface) void {
        if (eql(u8, "a", feedback)) {
            pok_transfer.bufferedPrint("\n", .{});
            caught.printMonDetails(null, self.mon - 1);
            pok_transfer.bufferedPrint("\n", .{});
        } else if (eql(u8, "b", feedback)) {
            self.mode = .PARTY;
        } else if (eql(u8, "c", feedback)) {
            caught.markForTransfer(null, self.mon - 1);
        } else if (eql(u8, "d", feedback)) {
            caught.unmarkForTransfer(null, self.mon - 1);
        } else {
            pok_transfer.bufferedPrint("Incorrect argument\n", .{});
        }
    }

    fn processBoxMon(self: *@This(), feedback: []const u8, caught: *interface.CaughtMonInterface) void {
        if (eql(u8, "a", feedback)) {
            pok_transfer.bufferedPrint("\n", .{});
            caught.printMonDetails(self.box - 1, self.mon - 1);
            pok_transfer.bufferedPrint("\n", .{});
        } else if (eql(u8, "b", feedback)) {
            self.mode = .BOX;
        } else if (eql(u8, "c", feedback)) {
            caught.markForTransfer(self.box - 1, self.mon - 1);
        } else if(eql(u8, "d", feedback)) {
            caught.unmarkForTransfer(self.box - 1, self.mon - 1);
        } else {
            pok_transfer.bufferedPrint("Incorrect argument\n", .{});
        }
    }

    fn processFeedback(self: *@This(), feedback: []const u8, caught: *interface.CaughtMonInterface) void {
        if (eql(u8, "x", feedback)) {
            self.mode = .EXIT;
            return;
        }

        if (self.mode == .GENERAL) {
            processGeneral(self, feedback, caught);
        } else if (self.mode == .BOX) {
            processBox(self, feedback, caught);
        } else if (self.mode == .PARTY) {
            processParty(self, feedback, caught);
        } else if (self.mode == .PARTY_MON) {
            processPartyMon(self, feedback, caught);
        } else if (self.mode == .BOX_MON) {
            processBoxMon(self, feedback, caught);
        }
    }
};

pub fn startTui(caught: *interface.CaughtMonInterface, io: std.Io) !void {
    var state: State = .{
        .mode = .GENERAL,
        .box = 0,
        .mon = 0,
    };

    var stdin_buffer: [512]u8 = undefined;
    var reader_p = std.Io.File.stdin().reader(io, &stdin_buffer);
    var reader = &reader_p.interface;
    while (true) {
        if (state.mode == .EXIT) {
            pok_transfer.bufferedPrint("Exiting.", .{});
            return;
        }

        state.printRelevantMenu(caught);

        reader.tossBuffered();
        const result = try reader.takeDelimiterExclusive(delimiter);
        state.processFeedback(result, caught);
    }
}