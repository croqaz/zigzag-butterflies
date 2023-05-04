const std = @import("std");
const p2d = @import("p2d.zig");
const log = @import("log.zig");
//
const String = []const u8;
const Point = p2d.Point;
const Direction = p2d.Direction;
const rand = @import("random.zig").random;
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
        const map = @import("main.zig").game.map;
        if (!map.isWalkable(&xy)) return false;
        self.xy = xy;
        return true;
    }
};

// Super-class wrapper hack, to overcome the lack of struct inheritance
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
            .none => true,
            else => false,
        };
    }

    pub fn isDead(self: *Self) bool {
        return switch (self.*) {
            .butter => |*s| s.*.dead,
            else => false,
        };
    }

    pub fn interact(self: *Self, player: *Player) bool {
        // When interact returns True, the other creature can move over
        // if False, the entity is like a block that cannot be steped over
        return switch (self.*) {
            .chest => |*s| s.*.interact(player),
            .butter => |*s| s.*.interact(player),
            else => true, // always move
        };
    }

    pub fn behave(self: *Self) void {
        switch (self.*) {
            .butter => |*s| s.*.behave(),
            else => {},
        }
    }
};

// Null entity hack; This is the "undefined" Thing;
// When an entity dies, it becomes Null
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

    fn interact(self: *Self, player: *Player) bool {
        // open/ close chest
        if (!self.open) {
            if (self.hasNet) {
                log.gameLog("You find a butterfly net!");
                player.foundNet = true;
            } else {
                log.gameLog("The chest is empty.");
            }
            self.open = false;
            self.ch = 'x';
        }
        return true;
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

    dead: bool = false,
    // how fast it can move every turn
    moveSpeed: u4 = 8,
    // how likely you can catch it
    agility: f32 = 6,

    fn interact(self: *Self, player: *Player) bool {
        // The player tries to catch this butterfly
        const rnd = @intToFloat(f32, rand().int(u4));
        const chance = if (player.foundNet == true) rnd else rnd / 2;
        if (chance < self.agility) {
            log.gameLog("You fail to catch a butterfly!");
            return false;
        } else {
            log.gameLog("You catch a butterfly!");
            self.dead = true;
        }
        return true;
    }

    fn behave(self: *Self) void {
        // The butterfly doesn't move all the time
        if (rand().int(u4) < self.moveSpeed) {
            return;
        }

        const map = @import("main.zig").game.map;
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

            // validate new position
            if (!map.isWalkable(&newPos)) continue;
            if (map.hasEntity(&newPos)) continue;

            self.xy = newPos;
            break;
        }
    }
};
