const std = @import("std");
const cfg = @import("config.zig");
const geom = @import("geom.zig");

// const Area = @import("area.zig").Area;
// const ViewPort = @import("view.zig").ViewPort;

const Direction = geom.Direction;
const Point = geom.Point;

pub const Game = struct {
    // game map/ area
    // map: Area = Area{},
    // viewPort logic
    // vw: ViewPort = ViewPort{},
    // exported public grid
    grid: [cfg.viewSize]u16 = [_]u16{32} ** cfg.viewSize,

    pub fn render(self: *Game) void {
        _ = self;
        // Iterate through all visible map cells
        // ...
        // Render all visible entities
        // ..
        // Render Player @ ViewPort center
    }

    pub fn turn(self: *Game, dir: Direction) void {
        _ = self;
        _ = dir;
        // If there are entities on map at the new point,
        // interact with the entity!! and if OK, player and view can move
    }
};

var game: Game = Game{};

pub export fn main() void {
    // ...
}

pub export fn turn(dir: Direction) void {
    return game.turn(dir);
}
