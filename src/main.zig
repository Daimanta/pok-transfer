const std = @import("std");
const builtin = @import("builtin");
const fs = std.fs;
const pok_transfer = @import("root.zig");

const tui = @import("tui/tui.zig");
const versions = @import("general/versions.zig");

const interface = @import("general/interface.zig");

const defaults = @import("defaults.zig");

const Allocator = std.mem.Allocator;
const Reader = std.fs.File.Reader;

const exit = std.posix.exit;

const Mode = enum {
    READ,
    TRANSFER
};


fn getMode(reader: *std.Io.Reader) Mode{
    pok_transfer.bufferedPrint("Welcome to pok-transfer. What would you like to do?\na) Inspect the contents of a save file\nb) Transfer Mon from one save-file to another\nAnswer: ", .{});
    var answer: []u8 = undefined;
    while (true) {
        reader.tossBuffered();
        answer = reader.takeDelimiterExclusive(tui.delimiter) catch {unreachable;};
        if (std.mem.eql(u8, "a", answer) or std.mem.eql(u8, "b", answer)) {
            break;
        }
        pok_transfer.bufferedPrint("Incorrect answer\nAnswer: ", .{});
    }

    return if (std.mem.eql(u8, "b", answer)) .TRANSFER else .READ;
}

fn getSourceFileLocation(mode: Mode, reader: *std.Io.Reader) []const u8 {
    const infix = if (mode == .READ) " " else " source ";
    pok_transfer.bufferedPrint("Enter{s}file [{s}]\nAnswer: ", .{infix, defaults.default_source_file_location});
    reader.tossBuffered();
    var source_file_location: []const u8 = reader.takeDelimiterExclusive(tui.delimiter) catch {unreachable;};
    if (source_file_location.len == 0) {
        source_file_location = defaults.default_source_file_location;
    }
    return source_file_location;
}

fn getSourceBytes(source_file_location: []const u8, allocator: Allocator) []u8 {
    var source_file = std.fs.cwd().openFile(source_file_location, .{}) catch {
        std.debug.print("Error", .{});
        exit(1);
    };

    const input_bytes = source_file.readToEndAlloc(allocator, 1 << 20) catch {
        std.debug.print("Error", .{});
        exit(1);
    };
    source_file.close();
    return input_bytes;
}

fn getDestinationFileLocation(mode: Mode, reader: *std.Io.Reader) ?[]const u8 {
    if (mode == .READ) return null;
    pok_transfer.bufferedPrint("Enter destination file [{s}]\nAnswer: ", .{defaults.default_destination_file_location});
    reader.tossBuffered();
    var destination_file_location: []const u8 = reader.takeDelimiterExclusive(tui.delimiter) catch {unreachable;};
    if (destination_file_location.len == 0) {
        destination_file_location = defaults.default_destination_file_location;
    }
    return destination_file_location;
}

fn getDestinationBytes(destination_file_location:?[]const u8, allocator: Allocator) ?[]u8 {
    if (destination_file_location == null) return null;
    var destination_file = std.fs.cwd().openFile(destination_file_location.?, .{}) catch {
        std.debug.print("Error", .{});
        exit(1);
    };

    const input_bytes = destination_file.readToEndAlloc(allocator, 1 << 20) catch {
        std.debug.print("Error", .{});
        exit(1);
    };
    destination_file.close();
    return input_bytes;

}

fn replaceBytesInFile(location: []const u8, bytes: []const u8) void {
    // Wipes file and writes replaced bytes
        _ = std.fs.cwd().createFile(location, .{.truncate = true}) catch {};
    var file = std.fs.cwd().openFile(location, .{.mode = .write_only}) catch {
        std.debug.print("Could not open file", .{});
        exit(1);
    };
    file.writeAll(bytes) catch {
        std.debug.print("Could not write to file", .{});
        exit(1);
    };
}

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();

    var stdin_buffer: [512]u8 = undefined;
    var reader_p = std.fs.File.stdin().reader(&stdin_buffer);
    const reader = &reader_p.interface;

    const mode = getMode(reader);
    const source_file_location = getSourceFileLocation(mode, reader);
    const source_bytes = getSourceBytes(source_file_location, allocator);
    const destination_file_location = getDestinationFileLocation(mode, reader);
    const destination_bytes_opt = getDestinationBytes(destination_file_location, allocator);

    const source_version = versions.determineVersion(source_bytes) catch {
        pok_transfer.bufferedPrint("Source file does not match any version known or checksum is corrupted. Exiting.\n", .{});
        exit(1);
    };

    if (source_version != .GEN1 and source_version != .GEN2GS and source_version != .GEN3FRLG) {
        pok_transfer.bufferedPrint("Only Gen 1,2,3 is supported at this moment. Exiting.\n", .{});
        exit(0);
    }

    if (mode == .TRANSFER and source_version != .GEN1) {
        pok_transfer.bufferedPrint("Only Gen 1 supports transfer at the moment. Exiting.\n", .{});
        exit(0);
    }


    var destination_version: ?versions.Version = null;
    if (destination_bytes_opt != null) {
        destination_version = versions.determineVersion(destination_bytes_opt.?) catch {
            pok_transfer.bufferedPrint("Destination file does not match any version known or checksum is corrupted. Exiting.\n", .{});
            exit(1);
        };
    }

    var caught_source = interface.CaughtMonInterface.init(source_version, source_bytes, allocator);
    tui.startTui(&caught_source) catch {};

    var caught_destination: ?interface.CaughtMonInterface = if (destination_bytes_opt != null) interface.CaughtMonInterface.init(destination_version.?, destination_bytes_opt.?, allocator) else null;

    if (mode == .TRANSFER) {
        interface.execute_move(&caught_source, &caught_destination.?);
        caught_source.toSave(source_bytes[0..caught_source.getSaveSize()]);
        caught_destination.?.toSave(destination_bytes_opt.?[0..caught_destination.?.getSaveSize()]);
        replaceBytesInFile(source_file_location, source_bytes);
        replaceBytesInFile(destination_file_location.?, destination_bytes_opt.?);
    }

}
