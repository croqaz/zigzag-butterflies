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
    tiles: [cfg.mapSize]u16 = [_]u16{32} ** cfg.mapSize,

    // all things on the map: actors & decor
    // used for turns & listing creatures
    ents: [46]Thing = undefined, // 10 + 12 + 10 + 8 + 4 + 2

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

        // draw grass
        var i: u8 = 0;
        while (i < 250) : (i += 1) {
            const x = randX();
            const y = randY();
            self.tiles[util.idxArea(u16, x, y)] = 39; // char '
        }

        // more map gen is done in JS

        const chestWithNet = rand().int(u3);
        var j: u8 = 0;
        i = 0;
        while (i < 10) : (i += 1) {
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
        while (i < 12) : (i += 1) {
            // TODO: random map position
            const x = randX();
            const y = randY();
            self.ents[j] = Thing{ .butter = things.Butterfly.newGrayButterfly(x, y) };
            j += 1;
        }
        i = 0;
        while (i < 10) : (i += 1) {
            // TODO: random map position
            const x = randX();
            const y = randY();
            self.ents[j] = Thing{ .butter = things.Butterfly.newBlueButterfly(x, y) };
            j += 1;
        }
        i = 0;
        while (i < 8) : (i += 1) {
            const x = randX();
            const y = randY();
            self.ents[j] = Thing{ .butter = things.Butterfly.newGreenButterfly(x, y) };
            j += 1;
        }
        i = 0;
        while (i < 4) : (i += 1) {
            const x = randX();
            const y = randY();
            self.ents[j] = Thing{ .butter = things.Butterfly.newRedButterfly(x, y) };
            j += 1;
        }
        i = 0;
        while (i < 2) : (i += 1) {
            const x = randX();
            const y = randY();
            self.ents[j] = Thing{ .butter = things.Butterfly.newElusiveButterfly(x, y) };
            j += 1;
        }
    }

    /// Check if Point is valid & walkable (not a wall)
    pub fn isWalkable(self: *const Self, xy: *const Point) bool {
        if (!xy.isValid()) return false;
        const idx = util.idxAreaXY(u16, xy);
        const cell = self.getTileAt(idx);
        if (cell == '#') return false;
        return true;
    }

    /// Get the tile at Point coord
    /// If coord is not inside the map, return a wall tile
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
        const k = util.idxAreaXY(u16, xy);
        if (self.coords.contains(k)) return true;
        return false;
    }

    /// Player interact at Point
    pub fn interactAt(self: *Self, xy: *const Point) bool {
        const k = util.idxAreaXY(u16, xy);
        const idx = self.coords.get(k);
        if (idx) |i| {
            // potentially in the future
            // entities could interact with each other
            const ok: bool = self.ents[i].interact(&self.player);
            return ok;
        }
        return true;
    }

    /// All entities on the map, act/ behave/ run their turn
    pub fn entitiesBehave(self: *Self) void {
        // TODO: check old map pos, before entity has moved!
        self.coords.clearAndFree(allocator);
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
            const k = util.idxAreaXY(u16, &xy);
            self.coords.put(allocator, k, i) catch continue;
        }
        // TODO: if entities have behaved, return True, to force re-render
    }
};
