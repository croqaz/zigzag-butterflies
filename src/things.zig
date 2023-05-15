const std = @import("std");
const p2d = @import("p2d.zig");
// const log = @import("log.zig");
//
const String = []const u8;
const Point = p2d.Point;
const rand = @import("random.zig").random;
const gameEvent = @import("js.zig").Imports.gameEvent;
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

    pub fn id(self: Self) u8 {
        return switch (self) {
            .none => 0,
            inline else => |s| s.id + 1,
        };
    }

    pub fn xy(self: *const Self) Point {
        return switch (self.*) {
            inline else => |*s| s.*.xy,
        };
    }

    pub fn isNone(self: Self) bool {
        return switch (self) {
            .none => true,
            else => false,
        };
    }

    pub fn isDead(self: Self) bool {
        return switch (self) {
            .butter => |s| s.dead,
            else => false,
        };
    }

    pub fn interact(self: *Self, player: *Player) bool {
        // When interact returns True, the other creature can move over
        // if False, the entity is like a block that cannot be steped over
        return switch (self.*) {
            .chest => |*s| s.*.interact(player),
            .butter => |*s| s.*.interact(player),
            else => true, // always move on "dead" entities
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
// When an entity dies, it becomes this None thing
pub const None = struct {
    // init with an invalid point
    xy: Point = Point{ .x = -1, .y = -1 },
};

pub const Chest = struct {
    const Self = @This();
    // visual char
    ch: u8 = 'X', // 88, 120
    // position on the map
    xy: Point = Point{ .x = 0, .y = 0 },
    // inspect id
    id: u8,

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
    // inspect id
    id: u8,

    // how fast it can move every turn
    lazyness: u4 = 8,
    // how likely you can catch it
    agility: f32 = 8,

    pub fn newGrayButterfly(id: u8, xy: Point) Butterfly {
        return Butterfly{ .id = id, .type = 0, .xy = xy };
    }

    pub fn newBlueButterfly(id: u8, xy: Point) Butterfly {
        return Butterfly{ .id = id, .type = 1, .lazyness = 9, .xy = xy };
    }

    pub fn newGreenButterfly(id: u8, xy: Point) Butterfly {
        return Butterfly{ .id = id, .type = 2, .agility = 13, .xy = xy };
    }

    pub fn newRedButterfly(id: u8, xy: Point) Butterfly {
        return Butterfly{ .id = id, .type = 3, .lazyness = 3, .agility = 14, .xy = xy };
    }

    pub fn newElusiveButterfly(id: u8, xy: Point) Butterfly {
        return Butterfly{ .id = id, .type = 4, .lazyness = 1, .agility = 15, .xy = xy };
    }

    /// The player tries to catch this butterfly
    fn interact(self: *Self, player: *Player) bool {
        // max value = 16
        var chance = @intToFloat(f32, rand().int(u4));
        if (player.foundNet) chance *= 1.2 else chance /= 1.5;
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
            const moveDir = @intToEnum(p2d.Direction, rand().int(u2));
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
