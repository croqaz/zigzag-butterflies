const std = @import("std");
const cfg = @import("config.zig");
const things = @import("things.zig");
const util = @import("util.zig");
// const log = @import("log.zig");
//
const Thing = things.Thing;
const Player = things.Player;
const Point = @import("p2d.zig").Point;
const rand = @import("random.zig").random;
//
// Game map/ area
//
pub const Area = struct {
    const Self = @This();

    // TODO :: maybe this can be improved?
    const allocator: std.mem.Allocator = std.heap.page_allocator;

    // player instance
    player: Player = Player{},

    // 2D background tiles, flat array
    // used for rendering on position
    tiles: [cfg.mapSize]u16 = undefined,

    // all things on the map: actors & decor
    // used for turns & listing creatures
    ents: [46]Thing = undefined, // 10 + 12 + 10 + 8 + 4 + 2

    // map coordinates -> ents array index
    coords: std.AutoHashMapUnmanaged(usize, usize) = std.AutoHashMapUnmanaged(usize, usize){},

    pub fn generateMapLvl1(self: *Self) void {
        @setCold(true);

        // draw grass
        var i: u8 = 0;
        while (i < 250) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(x, y)] = '"';
        }

        // more map gen is done in JS

        var j: u8 = 0;
        i = 0;
        // 10 chests
        while (i < 10) : (i += 1) {
            var chest = Thing{ .chest = things.Chest{ .id = j, .xy = self.getRandomCoord() } };
            if (i == 7) { // lucky!
                chest.chest.hasNet = true;
            }
            self.ents[j] = chest;
            j += 1;
        }
        i = 0;
        // 12 gray butterflies
        while (i < 12) : (i += 1) {
            const xy = self.getRandomCoord();
            self.ents[j] = Thing{ .butter = things.Butterfly.newGrayButterfly(j, xy) };
            j += 1;
        }
        i = 0;
        // 10 blue butterflies
        while (i < 10) : (i += 1) {
            const xy = self.getRandomCoord();
            self.ents[j] = Thing{ .butter = things.Butterfly.newBlueButterfly(j, xy) };
            j += 1;
        }
        i = 0;
        while (i < 8) : (i += 1) {
            const xy = self.getRandomCoord();
            self.ents[j] = Thing{ .butter = things.Butterfly.newGreenButterfly(j, xy) };
            j += 1;
        }
        i = 0;
        while (i < 4) : (i += 1) {
            const xy = self.getRandomCoord();
            self.ents[j] = Thing{ .butter = things.Butterfly.newRedButterfly(j, xy) };
            j += 1;
        }
        i = 0;
        while (i < 2) : (i += 1) {
            const xy = self.getRandomCoord();
            self.ents[j] = Thing{ .butter = things.Butterfly.newElusiveButterfly(j, xy) };
            j += 1;
        }
    }

    fn randX() u8 {
        const x = rand().int(u7);
        return if (x > cfg.mapWidth) x / 2 else @min(x, cfg.mapWidth - 1);
    }

    fn randY() u8 {
        const y = rand().int(u6);
        return if (y > cfg.mapHeight) y / 2 else @min(y, cfg.mapHeight - 1);
    }

    fn getRandomCoord(self: *const Self) Point {
        var tries: u8 = 250;
        while (tries > 0) : (tries -= 1) {
            const p = Point{ .x = randX(), .y = randY() };
            if (self.isWalkable(&p)) return p;
        }
        return undefined;
    }

    /// Check if Point is valid & walkable (not a wall)
    pub fn isWalkable(self: *const Self, xy: *const Point) bool {
        if (!xy.isValid()) return false;
        const idx = util.idxAreaXY(xy);
        const cell = self.getTileAt(idx);
        if (cell == '#') return false;
        return true;
    }

    /// Get the tile at Point coord
    /// If coord is outside the map, return a wall tile
    pub fn getTileAt(self: *const Self, idx: u16) u16 {
        if (idx < 0 or idx > cfg.mapSize) {
            return '#';
        } else {
            return self.tiles[idx];
        }
    }

    /// Check if there are entities (or Player) at Point
    pub fn hasEntity(self: *const Self, xy: *const Point) bool {
        if (self.player.xy.eq(xy)) return true;
        const k = util.idxAreaXY(xy);
        return self.coords.contains(k);
    }

    /// Player interacts with entity at Point
    pub fn interactAt(self: *Self, xy: *const Point) bool {
        const k = util.idxAreaXY(xy);
        const idx = self.coords.get(k);
        if (idx) |i| {
            // Future IDEA: entities could interact with each other
            return self.ents[i].interact(&self.player);
        }
        return true;
    }

    /// All entities on the map, act/ behave/ run their turn
    pub fn entitiesBehave(self: *Self) void {
        // self.coords.clearAndFree(allocator);
        for (&self.ents, 0..) |*e, i| {
            if (e.isDead()) {
                self.ents[i] = Thing{ .none = things.None{} };
                continue;
            }
            // remove old map position from coords
            var k = util.idxAreaXY(&e.xy());
            _ = self.coords.remove(k);

            // Future IDEA: check entity after behaving;
            // some entities may be destroyed after their turn
            // (but not in this game)
            e.*.behave();

            // put new map position in coords
            k = util.idxAreaXY(&e.xy());
            self.coords.put(allocator, k, i) catch continue;
        }
    }
};
