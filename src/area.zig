const std = @import("std");
const cfg = @import("config.zig");
const things = @import("things.zig");
const util = @import("util.zig");
const Point = @import("p2d.zig").Point;
const rand = @import("random.zig").random;
//
const Thing = things.Thing;
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
    // map IDX, entity mapping
    ents: std.AutoHashMapUnmanaged(u16, Thing) = std.AutoHashMapUnmanaged(u16, Thing){},

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

        self.ents.put(allocator, 9, Thing{ .chest = things.Chest{ .xy = Point{ .x = 9, .y = 9 } } }) catch return;
        self.ents.put(allocator, 15, Thing{ .chest = things.Chest{ .xy = Point{ .x = 9, .y = 9 } } }) catch return;

        self.ents.put(allocator, 5, Thing{ .butter = things.Butterfly{ .xy = Point{ .x = 5, .y = 5 } } }) catch return;
        self.ents.put(allocator, 25, Thing{ .butter = things.Butterfly{ .xy = Point{ .x = 25, .y = 25 } } }) catch return;
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
        const k = util.idxArea(@intCast(u16, xy.x), @intCast(u16, xy.y));
        if (self.ents.getPtr(k)) |e| {
            return e;
        }
        return undefined;
    }

    pub fn entitiesBehave(self: *Self) void {
        // All entities on the map, act/ behave/ run their turn
        var iterEnts = self.ents.valueIterator();
        while (iterEnts.next()) |e| {
            // TODO: if response is True, check entity
            // some entities may be destroyed after their turn
            _ = e.behave();
            // TODO: update position on the mapping
        }
    }
};
