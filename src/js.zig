const std = @import("std");

// Functions exported from JS env
pub const Imports = struct {
    pub extern fn gameLog(ptr: [*]const u8, len: usize) void;
    extern fn consoleLog(ptr: [*]const u8, len: usize) void;
    extern fn consoleFlush() void;
};

pub const Console = struct {
    pub const Logger = struct {
        pub const Error = error{};
        pub const Writer = std.io.Writer(void, Error, write);

        fn write(_: void, bytes: []const u8) Error!usize {
            Imports.consoleLog(bytes.ptr, bytes.len);
            return bytes.len;
        }
    };

    const logger = Logger.Writer{ .context = {} };

    pub fn log(comptime format: []const u8, args: anytype) void {
        logger.print(format, args) catch return;
        Imports.consoleFlush();
    }

    pub fn logErr(comptime format: []const u8, args: anytype) void {
        log("Error: " ++ format, args);
    }
};
