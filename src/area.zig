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
    ents: [16]Thing = undefined,

    // map coordinates -> ents array index
    coords: std.AutoHashMapUnmanaged(usize, usize) = std.AutoHashMapUnmanaged(usize, usize){},

    fn randX() u8 {
        const x = rand().int(u7);
        return if (x > cfg.mapWidth) x / 2 else @min(x, cfg.mapWidth - 1);
    }

    fn randY() u8 {
        const y = rand().int(u6);
        return if (y > cfg.mapHeight) y / 2 else @min(y, cfg.mapHeight - 1);
    }

    pub fn generateMapLvl1(self: *Self) void {
        @setCold(true);

        // more map gen is done in JS

        // draw grass
        var i: u8 = 0;
        while (i < 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(u16, x, y)] = 39; // char '
        }
        i = 0;
        while (i < 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(u16, x, y)] = '"';
        }
        i = 0;
        while (i < 100) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(u16, x, y)] = '.';
        }

        const chestWithNet = rand().int(u3);
        var j: u8 = 0;
        i = 0;
        while (i < std.math.maxInt(u3)) : (i += 1) {
            // TODO: random map position
            const x = randX();
            const y = randY();
            var chest = Thing{ .chest = things.Chest{ .xy = Point{ .x = x, .y = y } } };
            if (i == chestWithNet) {
                chest.chest.hasNet = true;
            }
            self.ents[j] = chest;
            j += 1;
        }

        i = 0;
        while (i < std.math.maxInt(u3)) : (i += 1) {
            // TODO: random map position
            const x = randX();
            const y = randY();
            self.ents[j] = Thing{ .butter = things.Butterfly{ .xy = Point{ .x = x, .y = y } } };
            j += 1;
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

    pub fn interactAt(self: *Self, xy: *const Point, player: *things.Player) bool {
        const k = util.idxArea(u16, xy.x, xy.y);
        const idx = self.coords.get(k);
        if (idx) |i| {
            const ok: bool = self.ents[i].interact(player);
            return ok;
        }
        return true;
    }

    pub fn entitiesBehave(self: *Self) void {
        self.coords.clearAndFree(allocator);
        // All entities on the map, act/ behave/ run their turn
        for (&self.ents, 0..) |*e, i| {
            if (e.isDead()) {
                self.ents[i] = Thing{ .none = things.None{} };
                continue;
            }
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
