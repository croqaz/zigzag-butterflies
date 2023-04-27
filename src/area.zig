const std = @import("std");
const cfg = @import("config.zig");
const things = @import("things.zig");
const util = @import("util.zig");
const rand = @import("random.zig").random;
//
const Point = @import("p2d.zig").Point;
const Thing = things.Thing;
//
// Game map/ area
//
pub const Area = struct {
    const Self = @This();

    // 2D background tiles, flat array
    // used for rendering on position
    tiles: [cfg.mapSize]u16 = [_]u16{32} ** cfg.mapSize,

    // all things on the map: actors & decor
    // used for turns & listing creatures
    // map IDX, entity mapping
    // ents: ...

    fn randX() u16 {
        var x: u7 = rand().int(u7);
        return if (x > cfg.mapWidth) x / 2 else @min(x, cfg.mapWidth - 1);
    }

    fn randY() u16 {
        var y: u6 = rand().int(u6);
        return if (y > cfg.mapHeight) y / 2 else @min(y, cfg.mapHeight - 1);
    }

    pub fn generateMapLvl1(self: *Self) void {
        @setCold(true);

        // more stuff will be done in JS

        // draw grass
        var i: u8 = 0;
        while (i <= 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(x, y)] = 39; // char '
        }
        i = 0;
        while (i <= 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(x, y)] = '"'; // 34 = char "
        }
    }

    pub fn getTileAt(self: *const Self, idx: u16) u16 {
        // If coord is not inside the map, return a wall tile
        if (idx < 0 or idx > cfg.mapSize) {
            return 35; // char #
        } else {
            return self.tiles[idx];
        }
    }

    pub fn getEntityAt(self: *Self, xy: *const Point) *Thing {
        _ = self;
        _ = xy;
        return undefined;
    }

    pub fn entitiesBehave(self: *Self) void {
        _ = self;
        // All entities on the map, act/ behave/ run their turn
        return;
    }
};
