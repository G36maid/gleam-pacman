//// Grid-based movement system for Pacman game.
////
//// Handles tile-aligned movement with smooth interpolation and turn buffering.

import gleam/int
import gleam/option.{type Option, None, Some}
import pacman/game_state.{
  type Direction, type GridPosition, type WorldPosition, Down, GridPosition,
  Left, Right, Up, WorldPosition,
}
import pacman/maze

/// Get the direction vector for a given direction
pub fn direction_to_vector(dir: Direction) -> #(Int, Int) {
  case dir {
    Up -> #(0, -1)
    Down -> #(0, 1)
    Left -> #(-1, 0)
    Right -> #(1, 0)
    game_state.None -> #(0, 0)
  }
}

/// Get opposite direction (for reversals)
pub fn opposite_direction(dir: Direction) -> Direction {
  case dir {
    Up -> Down
    Down -> Up
    Left -> Right
    Right -> Left
    game_state.None -> game_state.None
  }
}

/// Calculate next grid position based on current position and direction
pub fn next_grid_position(pos: GridPosition, dir: Direction) -> GridPosition {
  let #(dx, dy) = direction_to_vector(dir)
  GridPosition(x: pos.x + dx, y: pos.y + dy)
}

/// Check if movement in direction is valid (not blocked by wall)
pub fn can_move_to(
  maze: List(List(game_state.Tile)),
  from: GridPosition,
  dir: Direction,
) -> Bool {
  let next = next_grid_position(from, dir)
  !maze.is_wall_at(maze, next)
}

/// Move world position towards direction (with speed and delta time)
pub fn move_towards(
  world_pos: WorldPosition,
  dir: Direction,
  speed: Float,
  tile_size: Float,
  delta: Float,
) -> WorldPosition {
  let #(dx, dy) = direction_to_vector(dir)
  let distance = speed *. tile_size *. delta

  WorldPosition(
    x: world_pos.x +. int.to_float(dx) *. distance,
    y: world_pos.y +. int.to_float(dy) *. distance,
  )
}

/// Snap world position to grid center (used after crossing tile boundaries)
pub fn snap_to_tile_center(
  world_pos: WorldPosition,
  tile_size: Float,
) -> WorldPosition {
  let grid = game_state.world_to_grid(world_pos, tile_size)
  game_state.grid_to_world(grid, tile_size)
}

/// Check if entity crossed into a new tile
pub fn crossed_tile_boundary(
  old_pos: WorldPosition,
  new_pos: WorldPosition,
  tile_size: Float,
) -> Bool {
  let old_grid = game_state.world_to_grid(old_pos, tile_size)
  let new_grid = game_state.world_to_grid(new_pos, tile_size)

  old_grid.x != new_grid.x || old_grid.y != new_grid.y
}

/// Try to execute a buffered turn if entity is centered enough
pub fn try_buffered_turn(
  world_pos: WorldPosition,
  current_dir: Direction,
  buffered_dir: Option(Direction),
  maze: List(List(game_state.Tile)),
  tile_size: Float,
  threshold: Float,
) -> #(Direction, Option(Direction)) {
  case buffered_dir {
    Some(new_dir) -> {
      // Check if centered enough to turn
      let is_centered =
        game_state.is_centered_on_tile(world_pos, tile_size, threshold)

      case is_centered {
        True -> {
          let grid_pos = game_state.world_to_grid(world_pos, tile_size)
          // Check if the buffered direction is valid
          case can_move_to(maze, grid_pos, new_dir) {
            True -> #(new_dir, None)
            False -> #(current_dir, buffered_dir)
          }
        }
        False -> #(current_dir, buffered_dir)
      }
    }
    None -> #(current_dir, None)
  }
}

/// Handle tunnel wrapping (Pacman wraps around edges on specific rows)
/// Returns new position after wrapping (if applicable)
pub fn handle_tunnel_wrap(
  pos: WorldPosition,
  maze_width: Int,
  maze_height: Int,
  tile_size: Float,
) -> WorldPosition {
  let grid = game_state.world_to_grid(pos, tile_size)

  // Wrap horizontally
  let wrapped_x = case grid.x {
    x if x < 0 -> maze_width - 1
    x if x >= maze_width -> 0
    x -> x
  }

  // Wrap vertically (less common but possible)
  let wrapped_y = case grid.y {
    y if y < 0 -> maze_height - 1
    y if y >= maze_height -> 0
    y -> y
  }

  game_state.grid_to_world(GridPosition(x: wrapped_x, y: wrapped_y), tile_size)
}

/// Calculate movement for Pacman player with input buffering
pub fn update_player_movement(
  player: game_state.Player,
  input_dir: Option(Direction),
  maze: List(List(game_state.Tile)),
  speed: Float,
  tile_size: Float,
  threshold: Float,
  delta: Float,
  maze_width: Int,
  maze_height: Int,
) -> game_state.Player {
  // Try to apply buffered turn first
  let #(current_dir, new_buffered) =
    try_buffered_turn(
      player.world_pos,
      player.direction,
      player.next_direction,
      maze,
      tile_size,
      threshold,
    )

  // Update buffered direction if new input received
  let buffered_dir = case input_dir {
    Some(dir) if dir != current_dir -> Some(dir)
    _ -> new_buffered
  }

  // Move in current direction
  let new_world_pos =
    move_towards(player.world_pos, current_dir, speed, tile_size, delta)

  // Handle tunnel wrapping
  let wrapped_pos =
    handle_tunnel_wrap(new_world_pos, maze_width, maze_height, tile_size)

  // Update grid position
  let new_grid_pos = game_state.world_to_grid(wrapped_pos, tile_size)

  game_state.Player(
    grid_pos: new_grid_pos,
    world_pos: wrapped_pos,
    direction: current_dir,
    next_direction: buffered_dir,
  )
}
