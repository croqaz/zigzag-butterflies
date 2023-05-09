const std = @import("std");
const p2d = @import("p2d.zig");
// const log = @import("log.zig");
//
const String = []const u8;
const Point = p2d.Point;
const Direction = p2d.Direction;
const rand = @import("random.zig").random;
const gameEvent = @import("js.zig").Imports.gameEvent;
//
const GameEvent = enum(c_int) {
    // chestHasNet = 1,
    // chestEmpty = 2,
    // missGrayButterfly = 10,
    // missBlueButterfly,
    // missGreenButterfly,
    // missRedButterfly,
    // missElusiveButterfly,
    // catchGrayButterfly = 20,
    // catchBlueButterfly,
    // catchGreenButterfly,
    // catchRedButterfly,
    // catchElusiveButterfly,
};
//
pub const Player = struct {
    const Self = @This();
    ch: u8 = '@',
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
            .none => 0,
            .chest => |s| s.ch,
            .butter => |s| 'A' + s.type,
        };
    }

    pub fn xy(self: *const Self) Point {
        return switch (self.*) {
            inline else => |*s| s.*.xy,
        };
    }

    pub fn isNone(self: *const Self) bool {
        return switch (self.*) {
            .none => true,
            else => false,
        };
    }

    pub fn isDead(self: *const Self) bool {
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
    xy: Point = Point{ .x = -1, .y = -1 }, // invalid point
};

pub const Chest = struct {
    const Self = @This();
    // visual char
    ch: u8 = 'X', // 88, 120
    // position on the map
    xy: Point = Point{ .x = 0, .y = 0 },

    open: bool = false,
    hasNet: bool = false,

    fn interact(self: *Self, player: *Player) bool {
        // open/ close chest
        if (!self.open) {
            if (self.hasNet) {
                gameEvent(1);
                player.foundNet = true;
                self.hasNet = false;
            } else {
                gameEvent(2);
            }
            self.open = true;
            self.ch = 'x';
        }
        return true;
    }
};

pub const Butterfly = struct {
    const Self = @This();
    // position on the map
    xy: Point = Point{ .x = 0, .y = 0 },

    // the visual char is calculated from Type
    type: u8 = 0,
    dead: bool = false,

    // how fast it can move every turn
    lazyness: u4 = 8,
    // how likely you can catch it
    agility: f32 = 8,

    pub fn newGrayButterfly(xy: Point) Butterfly {
        return Butterfly{ .type = 0, .lazyness = 10, .agility = 7, .xy = xy };
    }

    pub fn newBlueButterfly(xy: Point) Butterfly {
        return Butterfly{ .type = 1, .lazyness = 10, .xy = xy };
    }

    pub fn newGreenButterfly(xy: Point) Butterfly {
        return Butterfly{ .type = 2, .lazyness = 8, .xy = xy };
    }

    pub fn newRedButterfly(xy: Point) Butterfly {
        return Butterfly{ .type = 3, .lazyness = 3, .agility = 10, .xy = xy };
    }

    pub fn newElusiveButterfly(xy: Point) Butterfly {
        return Butterfly{ .type = 4, .lazyness = 1, .agility = 14, .xy = xy };
    }

    /// The player tries to catch this butterfly
    fn interact(self: *Self, player: *Player) bool {
        // max value = 16
        var chance = @intToFloat(f32, rand().int(u4));
        if (!player.foundNet) chance /= 2;
        if (chance < self.agility) {
            gameEvent(10 + self.type);
        } else {
            gameEvent(20 + self.type);
            self.dead = true;
        }
        return self.dead;
    }

    fn behave(self: *Self) void {
        // The butterfly doesn't move all the time
        if (rand().int(u4) < self.lazyness) {
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
