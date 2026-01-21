/// Game State Module - Player, Ghosts, and Game Phase
import vec/vec2

/// Direction for movement
pub type Direction {
  Up
  Down
  Left
  Right
}

/// Opposite direction helper
pub fn opposite_direction(dir: Direction) -> Direction {
  case dir {
    Up -> Down
    Down -> Up
    Left -> Right
    Right -> Left
  }
}

/// Convert direction to grid offset
pub fn direction_to_offset(dir: Direction) -> vec2.Vec2(Int) {
  case dir {
    Up -> vec2.Vec2(0, -1)
    Down -> vec2.Vec2(0, 1)
    Left -> vec2.Vec2(-1, 0)
    Right -> vec2.Vec2(1, 0)
  }
}

/// Player state
pub type Player {
  Player(
    grid_pos: vec2.Vec2(Int),
    // Grid position (tile coordinates)
    direction: Direction,
    // Current facing direction
    next_direction: Direction,
    // Buffered turn input
    speed: Float,
    // Movement speed (tiles per second)
    power_mode: Bool,
    // Can eat ghosts?
    power_timer: Float,
    // Time remaining in power mode (seconds)
  )
}

/// Ghost personality types (affects AI behavior)
pub type GhostType {
  Blinky
  // Red - aggressive chaser
  Pinky
  // Pink - ambusher (targets ahead of player)
  Inky
  // Cyan - flanker (complex behavior)
  Clyde
  // Orange - random (leaves when too close)
}

/// Ghost behavior mode
pub type GhostMode {
  Scatter
  // Return to home corner
  Chase
  // Chase player
  Frightened
  // Flee from player (can be eaten)
  Eaten
  // Return to spawn after being eaten
}

/// Ghost state
pub type Ghost {
  Ghost(
    ghost_type: GhostType,
    grid_pos: vec2.Vec2(Int),
    direction: Direction,
    mode: GhostMode,
    mode_timer: Float,
    // Time remaining in current mode
    speed: Float,
    // Movement speed
  )
}

/// Overall game phase
pub type GamePhase {
  Playing(score: Int, lives: Int, level: Int, dots_remaining: Int)
  Paused(score: Int, lives: Int, level: Int)
  GameOver(final_score: Int)
  Victory(final_score: Int, level: Int)
}

/// Complete game state model
pub type Model {
  Model(
    player: Player,
    ghosts: List(Ghost),
    phase: GamePhase,
    maze: List(List(Tile)),
    // Dynamic maze (dots get eaten)
    time: Float,
    // Total game time
  )
}

/// Tile type (dynamic - changes as player eats dots)
pub type Tile {
  Wall
  Empty
  Dot
  PowerPellet
}

/// Initial player at spawn position (14, 23)
pub fn initial_player() -> Player {
  Player(
    grid_pos: vec2.Vec2(14, 23),
    direction: Left,
    next_direction: Left,
    speed: 8.0,
    // 8 tiles per second
    power_mode: False,
    power_timer: 0.0,
  )
}

/// Initial ghosts at spawn positions
pub fn initial_ghosts() -> List(Ghost) {
  [
    // Blinky (Red) - starts outside ghost house, above the door
    Ghost(
      ghost_type: Blinky,
      grid_pos: vec2.Vec2(14, 11),
      direction: Left,
      mode: Scatter,
      mode_timer: 7.0,
      speed: 7.5,
    ),
    // Pinky (Pink) - starts in ghost house center
    Ghost(
      ghost_type: Pinky,
      grid_pos: vec2.Vec2(14, 14),
      direction: Up,
      mode: Scatter,
      mode_timer: 7.0,
      speed: 7.5,
    ),
    // Inky (Cyan) - starts in ghost house left
    Ghost(
      ghost_type: Inky,
      grid_pos: vec2.Vec2(12, 14),
      direction: Up,
      mode: Scatter,
      mode_timer: 7.0,
      speed: 7.5,
    ),
    // Clyde (Orange) - starts in ghost house right
    Ghost(
      ghost_type: Clyde,
      grid_pos: vec2.Vec2(16, 14),
      direction: Up,
      mode: Scatter,
      mode_timer: 7.0,
      speed: 7.5,
    ),
  ]
}

/// Ghost color for rendering
pub fn ghost_color(ghost_type: GhostType) -> Int {
  case ghost_type {
    Blinky -> 0xFF0000
    // Red
    Pinky -> 0xFFB8FF
    // Pink
    Inky -> 0x00FFFF
    // Cyan
    Clyde -> 0xFFB852
    // Orange
  }
}

/// Frightened ghost color (all turn blue)
pub const frightened_color: Int = 0x2121DE
