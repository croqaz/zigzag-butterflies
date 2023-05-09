// Generate map based on this size
pub export const mapWidth: u8 = 120;
pub export const mapHeight: u8 = 100;
pub const mapSize: u16 = @as(u16, mapHeight) * @as(u16, mapWidth);

// ViewPort sizes
pub export const viewWidth: u8 = 36;
pub export const viewHeight: u8 = 18;
pub const viewSize: u16 = @as(u16, viewHeight) * @as(u16, viewWidth);
