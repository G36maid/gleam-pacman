//// Core game constants based on classic Pacman arcade specifications.
////
//// Classic Pacman uses a 28x31 tile grid with 8px tiles in the original,
//// but we'll use 16px tiles for better visibility on modern displays.

// Grid dimensions (classic Pacman layout)
pub const maze_width = 28

pub const maze_height = 31

// Tile size in pixels (world units)
pub const tile_size = 16.0

// Movement speeds (tiles per second)
pub const pacman_speed = 8.0

pub const ghost_speed_normal = 7.5

pub const ghost_speed_frightened = 6.0

pub const ghost_speed_tunnel = 4.0

// Ghost mode timings (seconds)
pub const scatter_duration_1 = 7.0

pub const chase_duration_1 = 20.0

pub const scatter_duration_2 = 7.0

pub const chase_duration_2 = 20.0

pub const scatter_duration_3 = 5.0

pub const chase_duration_3 = 20.0

pub const scatter_duration_4 = 5.0

// After 4th scatter, chase indefinitely
pub const frightened_duration = 6.0

pub const frightened_flash_time = 2.0

// Points
pub const dot_points = 10

pub const power_pellet_points = 50

pub const ghost_points_1 = 200

pub const ghost_points_2 = 400

pub const ghost_points_3 = 800

pub const ghost_points_4 = 1600

// Game settings
pub const starting_lives = 3

pub const extra_life_at = 10_000

// Colors (hex codes for materials)
pub const color_pacman = 0xFFFF00

// Yellow
pub const color_blinky = 0xFF0000

// Red (aggressive chaser)
pub const color_pinky = 0xFFB8FF

// Pink (ambusher)
pub const color_inky = 0x00FFFF

// Cyan (flanker)
pub const color_clyde = 0xFFB852

// Orange (shy patrol)
pub const color_frightened = 0x2121FF

// Blue (scared ghosts)
pub const color_frightened_flash = 0xFFFFFF

// White (flashing when timer low)
pub const color_wall = 0x2121FF

// Classic blue maze walls
pub const color_dot = 0xFFB897

// Pellet color
pub const color_power_pellet = 0xFFB897

// Same as dots but larger
// Viewport settings for 2D orthographic camera
pub const camera_distance = 300.0

pub const camera_height = 0.0

// Camera looks straight down
// Tile alignment threshold (for allowing turns)
// Pacman can only turn when within this distance of tile center
pub const turn_threshold = 2.0
