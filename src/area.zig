const std = @import("std");
const cfg = @import("config.zig");
const things = @import("things.zig");
const util = @import("util.zig");
// const log = @import("log.zig");
//
const Thing = things.Thing;
const Point = @import("p2d.zig").Point;
const rand = @import("random.zig").random;
//
// Game map/ area
//
pub const Area = struct {
    const Self = @This();
    const allocator: std.mem.Allocator = std.heap.page_allocator;

    // 2D background tiles, flat array
    // used for rendering on position
    tiles: [cfg.mapSize]u16 = [_]u16{32} ** cfg.mapSize,

    // all things on the map: actors & decor
    // used for turns & listing creatures
    ents: [5]Thing = undefined,

    // map coordinates -> ents array index
    coords: std.AutoHashMapUnmanaged(usize, usize) = std.AutoHashMapUnmanaged(usize, usize){},

    fn randX() u8 {
        var x: u7 = rand().int(u7);
        return if (x > cfg.mapWidth) x / 2 else @min(x, cfg.mapWidth - 1);
    }

    fn randY() u8 {
        var y: u6 = rand().int(u6);
        return if (y > cfg.mapHeight) y / 2 else @min(y, cfg.mapHeight - 1);
    }

    pub fn generateMapLvl1(self: *Self) void {
        @setCold(true);

        // more map gen is done in JS

        // draw grass
        var i: u8 = 0;
        while (i <= 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(u16, x, y)] = 39; // char '
        }
        i = 0;
        while (i <= 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(u16, x, y)] = '"';
        }
        i = 0;
        while (i <= 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(u16, x, y)] = '.';
        }

        i = 0;
        self.ents[i] = Thing{ .chest = things.Chest{ .xy = Point{ .x = 9, .y = 9 } } };
        i += 1;
        self.ents[i] = Thing{ .chest = things.Chest{ .xy = Point{ .x = 18, .y = 18 } } };

        i += 1;
        self.ents[i] = Thing{ .butter = things.Butterfly{ .xy = Point{ .x = 5, .y = 5 } } };
        i += 1;
        self.ents[i] = Thing{ .butter = things.Butterfly{ .xy = Point{ .x = 25, .y = 25 } } };
    }

    pub fn getTileAt(self: *const Self, idx: u16) u16 {
        // If coord is not inside the map, return a wall tile
        if (idx < 0 or idx > cfg.mapSize) {
            return 35; // char #
        } else {
            return self.tiles[idx];
        }
    }

    pub fn interactAt(self: *Self, xy: *const Point) bool {
        const k = util.idxArea(u16, xy.x, xy.y);
        const idx = self.coords.get(k);
        if (idx) |i| {
            return self.ents[i].interact();
        }
        return undefined;
    }

    pub fn entitiesBehave(self: *Self) void {
        self.coords.clearAndFree(allocator);
        // All entities on the map, act/ behave/ run their turn
        for (&self.ents, 0..) |*e, i| {
            // TODO: if response is True, check entity
            // some entities may be destroyed after their turn
            _ = e.*.behave();
            // update position on the map
            const xy = e.xy();
            const k = util.idxArea(u16, xy.x, xy.y);
            self.coords.put(allocator, k, i) catch continue;
        }
        // TODO: if entities have behaved, return True, to force re-render
    }
};
