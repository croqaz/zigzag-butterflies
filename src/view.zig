const cfg = @import("config.zig");
//
const Point = @import("p2d.zig").Point;
//
// View port/ Window
//
pub const ViewPort = struct {
    const Self = @This();
    // current center point
    // the player will be close, but not exactly here
    center: Point = Point{},
    // view rect, top & bottom
    // must be in sync with center
    topLeft: Point = Point{},
    botRight: Point = Point{ .x = cfg.viewWidth, .y = cfg.viewHeight },

    pub fn slideView(self: *Self, offset: Point) bool {
        // x & y are between -32..32
        const newP = self.center.plus(&offset);
        if (!newP.isValid()) {
            return false;
        }

        self.center = newP;

        // Make sure the x-axis doesn't go to the left of the left bound
        var topLeftX = @max(0, self.center.x - cfg.viewWidth / 2);
        // Make sure we still have enough space to fit an entire game screen
        topLeftX = @min(topLeftX, cfg.mapWidth - cfg.viewWidth);
        // Make sure the y-axis doesn't above the top bound
        var topLeftY = @max(0, self.center.y - cfg.viewHeight / 2);
        // Make sure we still have enough space to fit an entire game screen
        topLeftY = @min(topLeftY, cfg.mapHeight - cfg.viewHeight);

        // Make sure the top point is valid! The bottom point is close enough and will be valid
        const topP = Point{ .x = topLeftX, .y = topLeftY };
        if (topP.isValid()) {
            // Update internal positioning
            const botP = Point{ .x = topLeftX + cfg.viewWidth, .y = topLeftY + cfg.viewHeight };
            self.topLeft = topP;
            self.botRight = botP;
            return true;
        }

        return false;
    }
};
