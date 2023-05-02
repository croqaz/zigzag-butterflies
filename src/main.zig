const std = @import("std");
const cfg = @import("config.zig");
const p2d = @import("p2d.zig");
const random = @import("random.zig");
const things = @import("things.zig");
const util = @import("util.zig");
// const log = @import("log.zig");
//
const Area = @import("area.zig").Area;
const ViewPort = @import("view.zig").ViewPort;
//
const Direction = p2d.Direction;
const Player = things.Player;
const Point = p2d.Point;

pub const Game = struct {
    // game map/ area
    map: Area = Area{},
    // viewPort logic
    vw: ViewPort = ViewPort{},
    // player instance
    player: Player = Player{},
    // exported rendered grid
    grid: [cfg.viewSize]u16 = [_]u16{32} ** cfg.viewSize,

    // Update rendered grid
    pub fn render(self: *Game) void {
        // Iterate through all visible map cells
        var gridIndex: usize = 0;
        for (@intCast(u16, self.vw.topLeft.y)..@intCast(u16, self.vw.botRight.y)) |y| {
            for (@intCast(u16, self.vw.topLeft.x)..@intCast(u16, self.vw.botRight.x)) |x| {
                // TODO: map render @ x,y, would return Entity or Background!
                const i = util.idxArea(u16, @intCast(i16, x), @intCast(i16, y));
                self.grid[gridIndex] = self.map.getTileAt(i);
                gridIndex += 1;
            }
        }

        // Render all visible entities
        for (&self.map.ents) |*e| {
            if (e.isNone()) continue;
            const xy = e.xy();
            if (xy.isWithin(&self.vw.topLeft, &self.vw.botRight)) {
                const tXY = xy.minus(&self.vw.topLeft);
                self.grid[util.idxView(u16, tXY.x, tXY.y)] = e.ch();
            }
        }

        // Render Player @ ViewPort center
        const pXY = self.player.xy.minus(&self.vw.topLeft);
        self.grid[util.idxView(u16, pXY.x, pXY.y)] = self.player.ch;
    }

    // Player moves to a direction (or waits)
    // player interacts with entities at new point;
    // all entities take their turn to behave;
    pub fn turn(self: *Game, dir: Direction) bool {
        const offsetP = dir.toOffset();
        const newCenter = self.player.xy.plus(&offsetP);
        var viewMoved: bool = true;

        // If there are entities on map at the new point,
        // interact with the entity!! and if OK, player & view can move
        // Null entities always return OK on interact
        const ok = self.map.interactAt(&newCenter, &self.player);
        if (ok) {
            viewMoved = self.player.tryMove(newCenter) and
                game.vw.slideView(offsetP);
        }

        self.map.entitiesBehave();
        self.render();
        return viewMoved;
    }
};

var game: Game = Game{};

// Zig app entry
pub fn main() void {
    random.initRandom(0);
    game.map.generateMapLvl1();
}

// WASM lib entry
export fn init(seed: u32) void {
    random.initRandom(seed);
    game.map.generateMapLvl1();
    _ = game.turn(Direction.e);
    _ = game.turn(Direction.s);
}

export fn turn(dir: Direction) bool {
    return game.turn(dir);
}

// The returned pointer will be used as an offset integer to the WASM memory
export fn getViewPointer() [*]u16 {
    return @ptrCast([*]u16, &game.grid);
}

export fn getMapPointer() [*]u16 {
    return @ptrCast([*]u16, &game.map.tiles);
}
