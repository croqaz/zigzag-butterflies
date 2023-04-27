// Generate map based on this size
pub export const mapWidth: u8 = 100;
pub export const mapHeight: u8 = 60;
pub const mapSize: usize = @as(u16, mapHeight) * @as(u16, mapWidth);

// ViewPort sizes
pub export const viewWidth: u8 = 28;
pub export const viewHeight: u8 = 16;
pub const viewSize: usize = @as(u16, viewHeight) * @as(u16, viewWidth);