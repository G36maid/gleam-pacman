//// Game state types and state machine for Pacman.
////
//// Uses functional state transformations following MVU pattern.

import gleam/float
import gleam/int
import gleam/option.{type Option}

/// Direction that an entity is facing/moving
pub type Direction {
  Up
  Down
  Left
  Right
  None
}

/// Position in grid coordinates (tiles)
pub type GridPosition {
  GridPosition(x: Int, y: Int)
}

/// Position in world coordinates (pixels)
pub type WorldPosition {
  WorldPosition(x: Float, y: Float)
}

/// Tile content in the maze
pub type Tile {
  Empty
  Wall
  Dot
  PowerPellet
  GhostHouse
}

/// Ghost behavior mode
pub type GhostMode {
  Scatter
  Chase
  Frightened
  Dead
}

/// Individual ghost state
pub type Ghost {
  Ghost(
    id: String,
    grid_pos: GridPosition,
    world_pos: WorldPosition,
    direction: Direction,
    target_tile: Option(GridPosition),
    mode: GhostMode,
    scatter_target: GridPosition,
  )
}

/// Pacman entity state
pub type Player {
  Player(
    grid_pos: GridPosition,
    world_pos: WorldPosition,
    direction: Direction,
    next_direction: Option(Direction),
  )
}

/// Overall game phase
pub type GamePhase {
  Menu
  Playing
  LevelComplete
  GameOver
}

/// Complete game state
pub type GameState {
  GameState(
    phase: GamePhase,
    player: Player,
    ghosts: List(Ghost),
    maze: List(List(Tile)),
    score: Int,
    lives: Int,
    level: Int,
    dots_remaining: Int,
    ghost_mode: GhostMode,
    mode_timer: Float,
    mode_cycle_index: Int,
    frightened_timer: Float,
    ghosts_eaten_combo: Int,
  )
}

/// Convert grid position to world position (pixel coordinates)
pub fn grid_to_world(grid: GridPosition, tile_size: Float) -> WorldPosition {
  WorldPosition(
    x: int_to_float(grid.x) *. tile_size +. tile_size /. 2.0,
    y: int_to_float(grid.y) *. tile_size +. tile_size /. 2.0,
  )
}

/// Convert world position to grid position (snap to nearest tile)
pub fn world_to_grid(world: WorldPosition, tile_size: Float) -> GridPosition {
  GridPosition(
    x: float_to_int(world.x /. tile_size),
    y: float_to_int(world.y /. tile_size),
  )
}

/// Check if entity is centered on current tile (for turn decisions)
pub fn is_centered_on_tile(
  world: WorldPosition,
  tile_size: Float,
  threshold: Float,
) -> Bool {
  let grid = world_to_grid(world, tile_size)
  let center = grid_to_world(grid, tile_size)

  let dx = abs_float(world.x -. center.x)
  let dy = abs_float(world.y -. center.y)

  dx <. threshold && dy <. threshold
}

// Helper functions for type conversions
fn int_to_float(i: Int) -> Float {
  // Gleam stdlib int.to_float returns Float directly
  int.to_float(i)
}

fn float_to_int(f: Float) -> Int {
  // Use float.round for proper rounding
  float.round(f)
}

fn abs_float(f: Float) -> Float {
  float.absolute_value(f)
}
