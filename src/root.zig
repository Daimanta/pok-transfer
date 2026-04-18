//! By convention, root.zig is the root source file when making a library.
const std = @import("std");
const Io = std.Io;

var threaded: Io.Threaded = .init_single_threaded;
const io = threaded.io();

pub fn bufferedPrint(comptime fmt: []const u8, args: anytype) void {
    var stdout_buffer: [1024]u8 = undefined;
    var stdout_writer = std.Io.File.stdout().writer(io, &stdout_buffer);
    const stdout = &stdout_writer.interface;

    stdout.print(fmt, args) catch {};

    stdout.flush() catch {};
}

