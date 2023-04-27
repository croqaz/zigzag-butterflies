const cfg = @import("config.zig");

pub inline fn clamp(n: u16, max: u16) u16 {
    return @min(n, max);
}

pub inline fn idxArea(x: u16, y: u16) u16 {
    const z = x + y * cfg.mapWidth;
    return clamp(z, cfg.mapSize);
}

pub inline fn idxView(x: u16, y: u16) u16 {
    const z = x + y * cfg.viewWidth;
    return clamp(z, cfg.viewSize);
}
