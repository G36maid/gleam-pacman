import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import pacman/constants as c
import pacman/game_state as gs
import pacman/maze

/// Ghost personality types for different AI behaviors
pub type GhostPersonality {
  Blinky
  // Aggressive chaser - targets Pacman directly
  Pinky
  // Ambusher - targets 4 tiles ahead of Pacman
  Inky
  // Flanker - complex targeting based on Blinky and Pacman
  Clyde
  // Shy patrol - retreats when too close to Pacman
}

/// Calculate the next target tile for a ghost based on its mode and personality
pub fn calculate_target_tile(
  ghost: gs.Ghost,
  personality: GhostPersonality,
  player: gs.Player,
  blinky_pos: Option(gs.GridPosition),
) -> gs.GridPosition {
  case ghost.mode {
    gs.Scatter -> ghost.scatter_target
    gs.Chase -> chase_target(personality, player, ghost, blinky_pos)
    gs.Frightened -> ghost.grid_pos
    // Random movement handled separately
    gs.Dead -> gs.GridPosition(14, 11)
    // Ghost house center
  }
}

/// Calculate chase target based on ghost personality
fn chase_target(
  personality: GhostPersonality,
  player: gs.Player,
  ghost: gs.Ghost,
  blinky_pos: Option(gs.GridPosition),
) -> gs.GridPosition {
  case personality {
    Blinky -> blinky_target(player)
    Pinky -> pinky_target(player)
    Inky -> inky_target(player, blinky_pos)
    Clyde -> clyde_target(player, ghost)
  }
}

/// Blinky: Target Pacman's current position directly
fn blinky_target(player: gs.Player) -> gs.GridPosition {
  player.grid_pos
}

/// Pinky: Target 4 tiles ahead of Pacman's direction
fn pinky_target(player: gs.Player) -> gs.GridPosition {
  let offset = case player.direction {
    gs.Up -> gs.GridPosition(0, -4)
    gs.Down -> gs.GridPosition(0, 4)
    gs.Left -> gs.GridPosition(-4, 0)
    gs.Right -> gs.GridPosition(4, 0)
    gs.None -> gs.GridPosition(0, 0)
  }

  gs.GridPosition(
    x: player.grid_pos.x + offset.x,
    y: player.grid_pos.y + offset.y,
  )
}

/// Inky: Complex targeting - mirror Blinky's position through a point 2 tiles ahead of Pacman
fn inky_target(
  player: gs.Player,
  blinky_pos: Option(gs.GridPosition),
) -> gs.GridPosition {
  // Get point 2 tiles ahead of Pacman
  let offset = case player.direction {
    gs.Up -> gs.GridPosition(0, -2)
    gs.Down -> gs.GridPosition(0, 2)
    gs.Left -> gs.GridPosition(-2, 0)
    gs.Right -> gs.GridPosition(2, 0)
    gs.None -> gs.GridPosition(0, 0)
  }

  let pivot =
    gs.GridPosition(
      x: player.grid_pos.x + offset.x,
      y: player.grid_pos.y + offset.y,
    )

  // If Blinky position is available, calculate target as mirrored position
  case blinky_pos {
    Some(blinky) -> {
      let dx = pivot.x - blinky.x
      let dy = pivot.y - blinky.y
      gs.GridPosition(x: pivot.x + dx, y: pivot.y + dy)
    }
    None -> pivot
    // Fallback to pivot point if Blinky not available
  }
}

/// Clyde: Target Pacman when far away, retreat to scatter corner when close
fn clyde_target(player: gs.Player, ghost: gs.Ghost) -> gs.GridPosition {
  let distance = calculate_distance(ghost.grid_pos, player.grid_pos)

  // If within 8 tiles, retreat to scatter corner
  case distance <. 8.0 {
    True -> ghost.scatter_target
    False -> player.grid_pos
  }
}

/// Calculate Euclidean distance between two grid positions
fn calculate_distance(pos1: gs.GridPosition, pos2: gs.GridPosition) -> Float {
  let dx = int.to_float(pos2.x - pos1.x)
  let dy = int.to_float(pos2.y - pos1.y)
  let assert Ok(dist) = float.square_root(dx *. dx +. dy *. dy)
  dist
}

/// Choose next direction for ghost to move toward target tile
/// Uses simple pathfinding: prefer direction that reduces distance to target
pub fn choose_next_direction(
  ghost: gs.Ghost,
  target: gs.GridPosition,
  maze: List(List(gs.Tile)),
) -> gs.Direction {
  case ghost.mode {
    gs.Frightened -> choose_random_valid_direction(ghost, maze)
    _ -> choose_best_direction_to_target(ghost, target, maze)
  }
}

/// Choose direction that minimizes distance to target (no backtracking)
fn choose_best_direction_to_target(
  ghost: gs.Ghost,
  target: gs.GridPosition,
  maze: List(List(gs.Tile)),
) -> gs.Direction {
  // Get all possible directions (excluding opposite of current direction)
  let possible_dirs = get_valid_directions(ghost, maze)

  // Find direction with minimum distance to target
  case possible_dirs {
    [] -> ghost.direction
    // Keep current direction if no options
    [single] -> single
    _ -> {
      // Calculate distance for each direction and pick minimum
      let with_distances =
        list.map(possible_dirs, fn(dir) {
          let new_pos = apply_direction(ghost.grid_pos, dir)
          let dist = calculate_distance(new_pos, target)
          #(dir, dist)
        })

      let assert Ok(#(best_dir, _)) =
        list.reduce(with_distances, fn(acc, curr) {
          let #(_, acc_dist) = acc
          let #(_, curr_dist) = curr
          case curr_dist <. acc_dist {
            True -> curr
            False -> acc
          }
        })

      best_dir
    }
  }
}

/// Choose random valid direction (for frightened mode)
fn choose_random_valid_direction(
  ghost: gs.Ghost,
  maze: List(List(gs.Tile)),
) -> gs.Direction {
  let valid_dirs = get_valid_directions(ghost, maze)

  case valid_dirs {
    [] -> ghost.direction
    [single] -> single
    _ -> {
      // For now, just pick first valid direction
      // TODO: Add proper randomization
      let assert Ok(dir) = list.first(valid_dirs)
      dir
    }
  }
}

/// Get all valid directions ghost can move (excluding backtracking)
fn get_valid_directions(
  ghost: gs.Ghost,
  maze: List(List(gs.Tile)),
) -> List(gs.Direction) {
  let opposite = opposite_direction(ghost.direction)
  let all_dirs = [gs.Up, gs.Down, gs.Left, gs.Right]

  all_dirs
  |> list.filter(fn(dir) { dir != opposite })
  |> list.filter(fn(dir) {
    let new_pos = apply_direction(ghost.grid_pos, dir)
    case maze.get_tile(maze, new_pos) {
      Ok(tile) -> maze.is_walkable(tile)
      Error(_) -> False
    }
  })
}

/// Apply direction to position to get new position
fn apply_direction(pos: gs.GridPosition, dir: gs.Direction) -> gs.GridPosition {
  case dir {
    gs.Up -> gs.GridPosition(x: pos.x, y: pos.y - 1)
    gs.Down -> gs.GridPosition(x: pos.x, y: pos.y + 1)
    gs.Left -> gs.GridPosition(x: pos.x - 1, y: pos.y)
    gs.Right -> gs.GridPosition(x: pos.x + 1, y: pos.y)
    gs.None -> pos
  }
}

/// Get opposite direction (for preventing backtracking)
fn opposite_direction(dir: gs.Direction) -> gs.Direction {
  case dir {
    gs.Up -> gs.Down
    gs.Down -> gs.Up
    gs.Left -> gs.Right
    gs.Right -> gs.Left
    gs.None -> gs.None
  }
}

/// Update a single ghost's AI (target and direction)
pub fn update_ghost_ai(
  ghost: gs.Ghost,
  personality: GhostPersonality,
  player: gs.Player,
  blinky_pos: Option(gs.GridPosition),
  maze: List(List(gs.Tile)),
) -> gs.Ghost {
  // Calculate target tile
  let target = calculate_target_tile(ghost, personality, player, blinky_pos)

  // Choose direction at intersections (when centered on tile)
  let new_direction = case
    gs.is_centered_on_tile(ghost.world_pos, c.tile_size, c.turn_threshold)
  {
    True -> choose_next_direction(ghost, target, maze)
    False -> ghost.direction
  }

  gs.Ghost(..ghost, target_tile: Some(target), direction: new_direction)
}

/// Initialize a ghost with proper spawn position and behavior
pub fn spawn_ghost(
  personality: GhostPersonality,
  _maze_data: List(List(gs.Tile)),
) -> gs.Ghost {
  let #(spawn_pos, scatter_target, _color) = case personality {
    Blinky -> #(
      maze.get_blinky_spawn(),
      maze.get_blinky_scatter_target(),
      c.color_blinky,
    )
    Pinky -> #(
      maze.get_pinky_spawn(),
      maze.get_pinky_scatter_target(),
      c.color_pinky,
    )
    Inky -> #(
      maze.get_inky_spawn(),
      maze.get_inky_scatter_target(),
      c.color_inky,
    )
    Clyde -> #(
      maze.get_clyde_spawn(),
      maze.get_clyde_scatter_target(),
      c.color_clyde,
    )
  }

  let world_pos = gs.grid_to_world(spawn_pos, c.tile_size)

  gs.Ghost(
    id: ghost_id_from_personality(personality),
    grid_pos: spawn_pos,
    world_pos: world_pos,
    direction: gs.Left,
    // Initial direction
    target_tile: Some(scatter_target),
    mode: gs.Scatter,
    scatter_target: scatter_target,
  )
}

/// Convert personality to ghost ID string
fn ghost_id_from_personality(personality: GhostPersonality) -> String {
  case personality {
    Blinky -> "blinky"
    Pinky -> "pinky"
    Inky -> "inky"
    Clyde -> "clyde"
  }
}

/// Get ghost color based on personality
pub fn ghost_color(personality: GhostPersonality) -> Int {
  case personality {
    Blinky -> c.color_blinky
    Pinky -> c.color_pinky
    Inky -> c.color_inky
    Clyde -> c.color_clyde
  }
}
