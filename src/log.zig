const std = @import("std");
const js = @import("js.zig");

const builtin = @import("builtin");
const Target = std.Target;

// Debug log message; Shouldn't be used in production;
pub fn logMsg(comptime format: []const u8, args: anytype) void {
    if (builtin.os.tag == Target.Os.Tag.freestanding) {
        js.Console.log(format, args);
    } else {
        std.debug.print(format, args);
        // const stdout = std.io.getStdOut().writer();
        // stdout.print(fmt, args) catch return;
    }
}

// Debug log error; Shouldn't be used in production;
pub fn logErr(comptime format: []const u8, args: anytype) void {
    if (builtin.os.tag == Target.Os.Tag.freestanding) {
        js.Console.logErr(format, args);
    } else {
        std.debug.print(format, args);
    }
}
