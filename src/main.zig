const std = @import("std");
const cfg = @import("config.zig");
const p2d = @import("p2d.zig");
const random = @import("random.zig");
const things = @import("things.zig");
const util = @import("util.zig");

const Area = @import("area.zig").Area;
const ViewPort = @import("view.zig").ViewPort;

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
    // exported public grid
    grid: [cfg.viewSize]u16 = [_]u16{32} ** cfg.viewSize,

    pub fn render(self: *Game) void {
        // Iterate through all visible map cells
        var gridIndex: usize = 0;
        for (@intCast(u16, self.vw.topLeft.y)..@intCast(u16, self.vw.botRight.y)) |y| {
            for (@intCast(u16, self.vw.topLeft.x)..@intCast(u16, self.vw.botRight.x)) |x| {
                const i = util.idxArea(@intCast(u16, x), @intCast(u16, y));
                self.grid[gridIndex] = self.map.getTileAt(i);
                gridIndex += 1;
            }
        }

        // Render all visible entities
        // ...

        // Render Player @ ViewPort center
        const pXY = self.player.xy.minus(&self.vw.topLeft);
        self.grid[util.idxView(@intCast(u16, pXY.x), @intCast(u16, pXY.y))] = self.player.ch;
    }

    pub fn turn(self: *Game, dir: Direction) bool {
        const offsetP = dir.toOffset();
        const newCenter = self.player.xy.plus(&offsetP);
        var playerMoved: bool = true;

        // If there are entities on map at the new point,
        // interact with the entity!! and if OK, player and view can move
        // Null entities always return OK on interact
        playerMoved = self.player.tryMove(newCenter) and
            game.vw.slideView(offsetP);

        self.render();
        return playerMoved;
    }
};

var game: Game = Game{};

pub export fn main(seed: u32) void {
    random.initRandom(seed);
    game.map.generateMapLvl1();
    _ = game.turn(Direction.e);
    _ = game.turn(Direction.s);
}

pub export fn turn(dir: Direction) bool {
    return game.turn(dir);
}

// The returned pointer will be used as an offset integer to the WASM memory
pub export fn getViewPointer() [*]u16 {
    return @ptrCast([*]u16, &game.grid);
}

pub export fn getMapPointer() [*]u16 {
    return @ptrCast([*]u16, &game.map.tiles);
}
