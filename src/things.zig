const std = @import("std");
const log = @import("log.zig");
const p2d = @import("p2d.zig");
const rand = @import("random.zig").random;
//
const Direction = p2d.Direction;
const Point = p2d.Point;
const String = []const u8;
//
pub const Player = struct {
    const Self = @This();
    // visual char
    ch: u8 = '@',
    // short unique name
    name: String = "You",
    // some description
    // descrip: string,
    xy: Point = Point{ .x = 0, .y = 0 },

    foundNet: bool = false,

    pub fn tryMove(self: *Self, xy: Point) bool {
        if (!xy.isValid()) return false;
        if (self.xy.eq(&xy)) return false;
        // Get thing/ entity walkable and interact with it
        // ..
        // Check if we can walk on the tile and simply walk onto it
        // ..
        self.xy = xy;
        return true;
    }
};

pub const Thing = union(enum) {
    const Self = @This();
    none: None,
    chest: Chest,
    butter: Butterfly,

    pub fn ch(self: Self) u8 {
        return switch (self) {
            inline else => |s| s.ch,
        };
    }

    pub fn xy(self: Self) Point {
        return switch (self) {
            inline else => |s| s.xy,
        };
    }

    pub fn isNone(self: *Self) bool {
        return switch (self.*) {
            Self.none => true,
            else => false,
        };
    }

    pub fn interact(self: *Self) bool {
        return switch (self.*) {
            Self.chest => |*s| s.*.interact(),
            Self.butter => |*s| s.*.interact(),
            else => true, // always move
        };
    }

    pub fn behave(self: *Self) bool {
        return switch (self.*) {
            Self.chest => |*s| s.*.behave(),
            Self.butter => |*s| s.*.behave(),
            else => false,
        };
    }
};

// Null entity hack
pub const None = struct {
    ch: u8 = 0,
    name: String = "",
    xy: Point = Point{ .x = -1, .y = -1 }, // invalid point
};

pub const Chest = struct {
    const Self = @This();
    // visual char
    ch: u8 = 'X', // 88, 120
    // short unique name
    name: String = "Chest",
    // some description
    // descrip: string,
    xy: Point = Point{ .x = 0, .y = 0 },

    open: bool = false,
    hasNet: bool = false,

    fn interact(self: *Self) bool {
        // open/ close chest
        if (!self.open) {
            // log.logMsg("You open a chest!", .{});
            self.open = true;
            self.ch = 'x';
        }
        return true;
    }
    fn behave(self: Self) bool {
        _ = self;
        return false;
    }
};

pub const Butterfly = struct {
    const Self = @This();
    // visual char
    ch: u8 = 'B', // 66, 98
    // short unique name
    name: String = "Butterfly",
    // some description
    // descrip: string,
    xy: Point = Point{ .x = 0, .y = 0 },

    // how fast it can move every turn
    moveSpeed: u4 = 5,
    // how likely you can catch it
    agility: u4 = 5,

    fn interact(self: Self) bool {
        // calculate if the player can catch it
        // log.logMsg("You touch a butterfly!", .{});
        _ = self;
        return true;
    }

    fn behave(self: *Self) bool {
        // The butterfly doesn't move all the time
        if (rand().int(u4) < self.moveSpeed) {
            return false;
        }
        var tries: u4 = 3;
        while (tries > 0) : (tries -= 1) {
            // Flip coin to determine if moving in N,S,E,W direction
            const moveDir = @intToEnum(Direction, rand().int(u2));
            const offsetP = moveDir.toOffset();
            // Flip coin to determine if moving in ++ or -- direction
            const newPos = if (rand().boolean())
                self.xy.plus(&offsetP)
            else
                self.xy.minus(&offsetP);
            if (!newPos.isValid()) continue;
            self.xy = newPos;
            return true;
        }
        return false;
    }
};
