const cfg = @import("config.zig");
const p2d = @import("p2d.zig");
const Point = p2d.Point;

pub inline fn idxArea(comptime T: type, x: i16, y: i16) T {
    const z = @intCast(T, x) + @intCast(T, y) * cfg.mapWidth;
    return @min(z, cfg.mapSize);
}

pub inline fn idxAreaXY(comptime T: type, xy: *const Point) T {
    return idxArea(T, xy.x, xy.y);
}

pub inline fn idxViewXY(comptime T: type, xy: *const Point) T {
    const z = @intCast(T, xy.x) + @intCast(T, xy.y) * cfg.viewWidth;
    return @min(z, cfg.viewSize);
}
