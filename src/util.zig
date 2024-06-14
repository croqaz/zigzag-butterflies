const cfg = @import("config.zig");
const p2d = @import("p2d.zig");
const Point = p2d.Point;

pub inline fn idxArea(x: i16, y: i16) u16 {
    const z: u16 = @intCast(x + y * cfg.mapWidth);
    return @min(z, cfg.mapSize);
}

pub inline fn idxAreaXY(xy: *const Point) u16 {
    return idxArea(xy.x, xy.y);
}

pub inline fn idxViewXY(xy: *const Point) u16 {
    const z: u16 = @intCast(xy.x + xy.y * cfg.viewWidth);
    return @min(z, cfg.viewSize);
}
