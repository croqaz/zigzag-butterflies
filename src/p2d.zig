const cfg = @import("config.zig");

pub const Direction = enum(c_int) {
    x = -1, // None
    n = 0, // Up
    s = 1, // Down
    e = 2, // Right
    w = 3, // Left

    pub fn toOffset(self: Direction) Point {
        return switch (self) {
            // try to move Nord, up
            Direction.n => Point{ .x = 0, .y = -1 },
            // try to move South, down
            Direction.s => Point{ .x = 0, .y = 1 },
            // try to move E, right
            Direction.e => Point{ .x = 1, .y = 0 },
            // try to move W, left
            Direction.w => Point{ .x = -1, .y = 0 },
            // no movement
            else => Point{},
        };
    }
};

pub const Point = struct {
    x: i16 = 0,
    y: i16 = 0,

    pub fn init(x: i16, y: i16) @This() {
        return @This(){
            .x = x,
            .y = y,
        };
    }

    pub inline fn isValid(self: *const Point) bool {
        return (self.x >= 0 and
            self.x < cfg.mapWidth and
            self.y >= 0 and
            self.y < cfg.mapHeight);
    }

    pub fn isWithin(self: *const Point, topLeft: *const Point, botRight: *const Point) bool {
        return (self.x >= topLeft.x and
            self.x <= botRight.x and
            self.y >= topLeft.y and
            self.y <= botRight.y);
    }

    pub fn eq(self: *const Point, other: *const Point) bool {
        return self.x == other.x and self.y == other.y;
    }

    pub fn plus(self: *const Point, other: *const Point) Point {
        return Point{
            .x = self.x + other.x,
            .y = self.y + other.y,
        };
    }

    pub fn minus(self: *const Point, other: *const Point) Point {
        return Point{
            .x = self.x - other.x,
            .y = self.y - other.y,
        };
    }

    pub fn dist(self: *const Point, other: *const Point) u16 {
        const dx = (other.x - self.x);
        const dy = (other.y - self.y);
        return @sqrt(dx * dx + dy * dy).round();
    }
};
