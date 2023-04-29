const cfg = @import("config.zig");

pub inline fn idxArea(comptime T: type, x: i16, y: i16) T {
    const z = @intCast(T, x) + @intCast(T, y) * cfg.mapWidth;
    return @min(z, cfg.mapSize);
}

pub inline fn idxView(comptime T: type, x: i16, y: i16) T {
    const z = @intCast(T, x) + @intCast(T, y) * cfg.viewWidth;
    return @min(z, cfg.viewSize);
}
