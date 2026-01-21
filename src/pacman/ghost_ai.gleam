/// Ghost AI system - pathfinding and personality behaviors
import gleam/int
import gleam/list
import pacman/game_state as gs
import pacman/movement
import vec/vec2

/// Update all ghosts' AI and movement
pub fn update_ghosts(
  ghosts: List(gs.Ghost),
  player_pos: vec2.Vec2(Int),
  maze: List(List(gs.Tile)),
  delta_seconds: Float,
  player_power_mode: Bool,
) -> List(gs.Ghost) {
  ghosts
  |> list.map(fn(ghost) {
    update_ghost(ghost, player_pos, maze, delta_seconds, player_power_mode)
  })
}

/// Update single ghost AI and movement
fn update_ghost(
  ghost: gs.Ghost,
  player_pos: vec2.Vec2(Int),
  maze: List(List(gs.Tile)),
  delta_seconds: Float,
  player_power_mode: Bool,
) -> gs.Ghost {
  // Update mode based on player power mode and timer
  let ghost_with_mode =
    update_ghost_mode(ghost, delta_seconds, player_power_mode)

  // Get target position based on ghost personality and mode
  let target_pos = get_target_position(ghost_with_mode, player_pos)

  // Choose next direction toward target
  let new_direction = choose_direction(ghost_with_mode, target_pos, maze)

  // Move ghost
  move_ghost(
    gs.Ghost(..ghost_with_mode, direction: new_direction),
    maze,
    delta_seconds,
  )
}

/// Update ghost mode based on timer and player power mode
fn update_ghost_mode(
  ghost: gs.Ghost,
  delta_seconds: Float,
  player_power_mode: Bool,
) -> gs.Ghost {
  // If player is in power mode, switch to Frightened
  case player_power_mode {
    True ->
      case ghost.mode {
        gs.Frightened -> {
          // Already frightened, just update timer
          gs.Ghost(..ghost, mode_timer: ghost.mode_timer -. delta_seconds)
        }
        gs.Eaten -> ghost
        // Don't change eaten ghosts
        _ ->
          // Switch to frightened mode
          gs.Ghost(..ghost, mode: gs.Frightened, mode_timer: 8.0)
      }
    False ->
      case ghost.mode {
        gs.Frightened -> {
          // Power mode ended, return to scatter
          gs.Ghost(..ghost, mode: gs.Scatter, mode_timer: 7.0)
        }
        gs.Eaten -> {
          // Check if reached ghost house
          case ghost.grid_pos == vec2.Vec2(14, 14) {
            True -> gs.Ghost(..ghost, mode: gs.Scatter, mode_timer: 7.0)
            False -> ghost
          }
        }
        _ -> {
          // Normal mode switching (Scatter ↔ Chase)
          let new_timer = ghost.mode_timer -. delta_seconds
          case new_timer <=. 0.0 {
            True -> {
              // Switch mode
              case ghost.mode {
                gs.Scatter ->
                  gs.Ghost(..ghost, mode: gs.Chase, mode_timer: 20.0)
                gs.Chase -> gs.Ghost(..ghost, mode: gs.Scatter, mode_timer: 7.0)
                _ -> ghost
              }
            }
            False -> gs.Ghost(..ghost, mode_timer: new_timer)
          }
        }
      }
  }
}

/// Get target position based on ghost type and mode
fn get_target_position(
  ghost: gs.Ghost,
  player_pos: vec2.Vec2(Int),
) -> vec2.Vec2(Int) {
  case ghost.mode {
    gs.Chase -> {
      // Each ghost has different targeting behavior
      case ghost.ghost_type {
        gs.Blinky ->
          // Blinky targets player directly (aggressive)
          player_pos
        gs.Pinky ->
          // Pinky targets 4 tiles ahead of player (ambusher)
          vec2.Vec2(player_pos.x, player_pos.y - 4)
        gs.Inky ->
          // Inky has complex behavior - for now just target player
          player_pos
        gs.Clyde -> {
          // Clyde targets player when far, scatter when close
          let distance = manhattan_distance(ghost.grid_pos, player_pos)
          case distance > 8 {
            True -> player_pos
            False -> vec2.Vec2(0, 30)
            // Scatter to bottom-left
          }
        }
      }
    }
    gs.Scatter -> {
      // Each ghost goes to their home corner
      case ghost.ghost_type {
        gs.Blinky -> vec2.Vec2(25, 0)
        // Top-right
        gs.Pinky -> vec2.Vec2(2, 0)
        // Top-left
        gs.Inky -> vec2.Vec2(27, 30)
        // Bottom-right
        gs.Clyde -> vec2.Vec2(0, 30)
        // Bottom-left
      }
    }
    gs.Frightened -> {
      // Move randomly away from player
      vec2.Vec2(0, 0)
    }
    gs.Eaten -> {
      // Return to ghost house
      vec2.Vec2(14, 14)
    }
  }
}

/// Choose best direction toward target
fn choose_direction(
  ghost: gs.Ghost,
  target: vec2.Vec2(Int),
  maze: List(List(gs.Tile)),
) -> gs.Direction {
  let current_pos = ghost.grid_pos

  // Try all four directions
  let directions = [gs.Up, gs.Down, gs.Left, gs.Right]

  // Filter out: walls, reversing direction
  let valid_directions =
    directions
    |> list.filter(fn(dir) {
      let offset = gs.direction_to_offset(dir)
      let next_pos =
        vec2.Vec2(current_pos.x + offset.x, current_pos.y + offset.y)

      // Don't reverse direction unless stuck
      let is_reverse = dir == gs.opposite_direction(ghost.direction)

      movement.is_walkable(maze, next_pos) && !is_reverse
    })

  // If no valid directions (stuck), allow reversing
  let final_directions = case valid_directions {
    [] -> [gs.opposite_direction(ghost.direction)]
    dirs -> dirs
  }

  // Choose direction closest to target
  final_directions
  |> list.fold(ghost.direction, fn(best_dir, dir) {
    let offset = gs.direction_to_offset(dir)
    let next_pos = vec2.Vec2(current_pos.x + offset.x, current_pos.y + offset.y)
    let dist = manhattan_distance(next_pos, target)

    let best_offset = gs.direction_to_offset(best_dir)
    let best_pos =
      vec2.Vec2(current_pos.x + best_offset.x, current_pos.y + best_offset.y)
    let best_dist = manhattan_distance(best_pos, target)

    case dist < best_dist {
      True -> dir
      False -> best_dir
    }
  })
}

/// Move ghost (similar to player movement but simpler)
fn move_ghost(
  ghost: gs.Ghost,
  maze: List(List(gs.Tile)),
  delta_seconds: Float,
) -> gs.Ghost {
  // Accumulate movement time
  let new_accumulator = ghost.move_accumulator +. delta_seconds *. ghost.speed

  // Move one tile when accumulator >= 1.0
  case new_accumulator >=. 1.0 {
    True -> {
      let offset = gs.direction_to_offset(ghost.direction)
      let target_pos =
        vec2.Vec2(ghost.grid_pos.x + offset.x, ghost.grid_pos.y + offset.y)

      // Handle tunnel wrapping
      let wrapped_pos = wrap_position(target_pos)

      case movement.is_walkable(maze, wrapped_pos) {
        True ->
          gs.Ghost(
            ..ghost,
            grid_pos: wrapped_pos,
            move_accumulator: new_accumulator -. 1.0,
          )
        False -> gs.Ghost(..ghost, move_accumulator: new_accumulator -. 1.0)
      }
    }
    False -> gs.Ghost(..ghost, move_accumulator: new_accumulator)
  }
}

/// Wrap position for tunnel
fn wrap_position(pos: vec2.Vec2(Int)) -> vec2.Vec2(Int) {
  let wrapped_x = case pos.x {
    x if x < 0 -> 27
    x if x > 27 -> 0
    x -> x
  }
  vec2.Vec2(wrapped_x, pos.y)
}

/// Calculate Manhattan distance
fn manhattan_distance(a: vec2.Vec2(Int), b: vec2.Vec2(Int)) -> Int {
  int.absolute_value(a.x - b.x) + int.absolute_value(a.y - b.y)
}
