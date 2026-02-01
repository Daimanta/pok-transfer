const std = @import("std");
const gen1 = @import("../gen1/mon.zig");
const gen2 = @import("../gen2GS/mon.zig");

const versions = @import("versions.zig");
const root = @import("../root.zig");

pub const CaughtMonInterface = union(enum) {
      gen1: gen1.CaughtMon,
      gen2gs: gen2.CaughtMon,

      pub fn init(version: versions.Version, bytes: []const u8, allocator: std.mem.Allocator) CaughtMonInterface {
          if (version == .GEN1) {
              return .{
                  .gen1 = gen1.CaughtMon.init(bytes, allocator)
              };
          } else if (version == .GEN2GS) {
              return .{
                  .gen2gs = gen2.CaughtMon.init(bytes, allocator)
              };
          } else {
              unreachable;
          }
      }

      pub fn printSummary(self: *const CaughtMonInterface) void {
          switch (self.*) {
              .gen1 => |x| gen1.CaughtMon.printSummary(&x),
              .gen2gs => |x| gen2.CaughtMon.printSummary(&x)
          }
      }

      pub fn printBoxSummary(self: *const CaughtMonInterface, box_index: u8) void {
          switch (self.*) {
              .gen1 => |x| x.boxes[box_index].printSummary(),
              .gen2gs => |x| x.boxes[box_index].printSummary()
          }
      }

      pub fn printPartySummary(self: *const CaughtMonInterface) void {
          switch (self.*) {
              .gen1 => |x| x.party.printSummary(),
              .gen2gs => |x| x.party.printSummary()
          }
      }

      pub fn printMonDetails(self: *const CaughtMonInterface, box: ?u8, mon: u8) void {
          switch (self.*) {
              .gen1 => |x| {
                  if (box == null) {
                      x.party.mons[mon].printFullSummary();
                  } else {
                      x.boxes[box.?].mons[mon].printFullSummary();
                  }
              },
              .gen2gs => |x| {
                  if (box == null) {
                      x.party.mons[mon].printFullSummary();
                  } else {
                      x.boxes[box.?].mons[mon].printFullSummary();
                  }
              }
          }
      }

    pub fn getCurrentBoxSize(self: *const CaughtMonInterface, box_index: u8) u8 {
        return switch (self.*) {
            .gen1 => |x| x.boxes[box_index].number_of_mon,
            .gen2gs => |x| x.boxes[box_index].number_of_mon
        };
    }

    pub fn getCurrentPartySize(self: *const CaughtMonInterface) u8 {
        return switch (self.*) {
            .gen1 => |x| x.party.number_of_mon,
            .gen2gs => |x| x.party.number_of_mon
        };
    }

    pub fn markForTransfer(self: *CaughtMonInterface, box: ?u8, mon: u8) void {
        switch (self.*) {
            .gen1 => self.gen1.markForTransfer(box, mon),
            .gen2gs => self.gen2gs.markForTransfer(box, mon)
        }
    }

      pub fn unmarkForTransfer(self: *CaughtMonInterface, box: ?u8, mon: u8) void {
          switch (self.*) {
              .gen1 => self.gen1.markForTransfer(box, mon),
              .gen2gs => self.gen2gs.markForTransfer(box, mon)
          }
      }

      pub fn getMoveMon(self: *CaughtMonInterface) MoveMon {
          return switch (self.*) {
              .gen1 => self.gen1.move_mon,
              .gen2gs => self.gen2gs.move_mon
          };
      }

    pub fn removeMon(self: *CaughtMonInterface, box: ?u8, mon: u8) void {
        switch (self.*) {
            .gen1 => self.gen1.removeMon(box, mon),
            .gen2gs => self.gen2gs.removeMon(box, mon),
        }
    }

    pub fn getMon(self: *CaughtMonInterface, box: ?u8, mon: u8) MonInterface {
        return switch (self.*) {
            .gen1 => .{.gen1 = self.gen1.getMon(box, mon)},
            .gen2gs => .{.gen2gs = self.gen2gs.getMon(box, mon)}
        };
    }

    pub fn toSave(self: *CaughtMonInterface, save_bytes: []u8) void {
        switch (self.*) {
            .gen1 => self.gen1.toSave(save_bytes[0..gen1.save_size]),
            .gen2gs => self.gen2gs.toSave(save_bytes[0..gen2.save_size]),
        }
    }

    pub fn getSaveSize(self: *CaughtMonInterface) usize  {
        return switch (self.*) {
            .gen1 => gen1.save_size,
            .gen2gs => gen2.save_size,
        };
    }

    pub fn getVersion(self: *CaughtMonInterface) versions.Version {
        return switch (self.*) {
            .gen1 => self.gen1.getVersion(),
            .gen2gs => self.gen2gs.getVersion()
        };
    }

    pub fn insertMon(self: *CaughtMonInterface, mon: MonInterface) !void {
        switch (self.*) {
            .gen1 => try self.gen1.insertMon(mon),
            .gen2gs => try self.gen2gs.insertMon(mon)
        }
    }


    pub fn getFreeSpace(self: *CaughtMonInterface) u16 {
        return switch (self.*) {
            .gen1 => self.gen1.getFreeSpace(),
            .gen2gs => self.gen2gs.getFreeSpace()
        };
    }

};

pub const MonInterface = union(enum) {
    gen1: gen1.Mon,
    gen2gs: gen2.Mon,

    pub fn canConvertToGen(self: *@This(), version: versions.Version) bool {
        switch (self.*) {
            .gen1 => {
                // Only up from gen1
                return true;
            },
            .gen2gs => {
                if (version == .GEN2GS) {
                    return true;
                } else if (version == .GEN3FRLG) {
                    return true;
                } else if (version == .GEN1) {
                    return self.gen2gs.canConvertToGen1();
                } else {
                    return false;
                }
            }
        }
    }

};

pub const MoveMon = struct {
    party_mon: []bool,
    box_mon: [][]bool,

    pub fn init(party_size: u8, box_size: u8, box_count: u8, allocator: std.mem.Allocator) @This() {
        var box_mon = allocator.alloc([]bool, box_count) catch {std.posix.exit(1);};
        var i: usize = 0;
        while (i < box_mon.len): (i += 1) {
            box_mon[i] = allocator.alloc(bool, box_size) catch {std.posix.exit(1);};
        }

        return .{
            .party_mon = allocator.alloc(bool, party_size) catch {std.posix.exit(1);},
            .box_mon = box_mon
        };
    }

    pub fn number_moved(self: *const @This()) u16 {
        var result: u16 = 0;
        for (self.party_mon) |mon| {
            if (mon) {
                result += 1;
            }
        }
        for (self.box_mon) |box| {
            for (box) |mon| {
                if (mon) {
                    result += 1;
                }
            }
        }

        return result;
    }
};


pub fn execute_move(source: *CaughtMonInterface, destination: *CaughtMonInterface) void {
    var party_transfers: u8 = 0;
    const party_size = source.getCurrentPartySize();

    var move_mon = source.getMoveMon();
    for (move_mon.party_mon) |bl| {
        if (bl) {
            party_transfers += 1;
        }
    }

    if (party_transfers == party_size) {
        move_mon.party_mon[0] = false;
    }

    const number_moved = move_mon.number_moved();
    const free_space = destination.getFreeSpace();
    if (number_moved > destination.getFreeSpace()) {
        root.bufferedPrint("Tried to move more mon ({d}) than free space available ({d}). Exiting", .{number_moved, free_space});
    }

    var k: usize = 6;
    while (k > 0): (k -= 1) {
        const kx = k - 1;
        if (move_mon.party_mon[kx]) {
            const mon = source.getMon(null, @intCast(kx));
            var insertion_error: ?anyerror = null;
            destination.insertMon(mon) catch |err| {
                insertion_error = err;
            };
            if (insertion_error == null) {
                source.removeMon(null, @intCast(kx));
            } else {
                root.bufferedPrint("Could not insert marked pokemon: {any}", .{insertion_error.?});
            }
        }
    }

    var i: usize = 0;
    while (i < move_mon.box_mon.len): ( i += 1) {
        const move_box = move_mon.box_mon[i];
        var j: usize = move_box.len;
        while (j > 0): ( j -= 1) {
            const jx = j - 1;
            if (move_box[jx]) {
                const mon = source.getMon(@intCast(i), @intCast(jx));
                var insertion_error: ?anyerror = null;
                destination.insertMon(mon) catch |err| {
                    insertion_error = err;
                };
                if (insertion_error == null) {
                    source.removeMon(@intCast(i), @intCast(jx));
                } else {
                    root.bufferedPrint("Could not insert marked pokemon: {any}", .{insertion_error.?});
                }
            }
        }
    }
}




