/// Movement system for Pac-Man - grid-based movement with turn buffering
import pacman/game_state as gs
import vec/vec2

/// Check if a tile is walkable (generic - used by player)
pub fn is_walkable(maze: List(List(gs.Tile)), pos: vec2.Vec2(Int)) -> Bool {
  case list_at(maze, pos.y) {
    Ok(row) ->
      case list_at(row, pos.x) {
        Ok(gs.Wall) -> False
        Ok(gs.Door) -> False
        // Player cannot walk through door
        Ok(_) -> True
        Error(_) -> False
      }
    Error(_) -> False
  }
}

/// Check if a tile is walkable for ghosts (can pass through door when exiting/returning)
pub fn is_walkable_for_ghost(
  maze: List(List(gs.Tile)),
  pos: vec2.Vec2(Int),
  house_state: gs.GhostHouseState,
) -> Bool {
  // Special case: Returning (eaten) ghosts can walk through ALL walls everywhere
  case house_state {
    gs.Returning -> {
      // Eaten ghosts can walk through any wall tile
      case list_at(maze, pos.y) {
        Ok(row) ->
          case list_at(row, pos.x) {
            Ok(gs.Wall) -> True
            // Eaten ghosts phase through walls
            Ok(gs.Door) -> True
            // Can pass through door
            Ok(_) -> True
            Error(_) -> False
          }
        Error(_) -> False
      }
    }
    _ -> check_tile_walkable(maze, pos, house_state)
  }
}

/// Helper to check tile walkability with door access control
fn check_tile_walkable(
  maze: List(List(gs.Tile)),
  pos: vec2.Vec2(Int),
  house_state: gs.GhostHouseState,
) -> Bool {
  case list_at(maze, pos.y) {
    Ok(row) ->
      case list_at(row, pos.x) {
        Ok(gs.Wall) -> False
        Ok(gs.Door) -> {
          // Door is only walkable when exiting or returning
          case house_state {
            gs.Exiting -> True
            gs.Returning -> True
            _ -> False
          }
        }
        Ok(_) -> True
        Error(_) -> False
      }
    Error(_) -> False
  }
}

/// Move player with proper frame-rate-independent movement
pub fn move_player(
  player: gs.Player,
  maze: List(List(gs.Tile)),
  delta_seconds: Float,
) -> gs.Player {
  // Accumulate movement time
  let new_accumulator = player.move_accumulator +. delta_seconds *. player.speed

  // Move one tile when accumulator >= 1.0
  case new_accumulator >=. 1.0 {
    True -> {
      // Try to execute buffered turn first
      let player_after_turn = try_turn(player, maze)

      // Move in current direction
      let offset = gs.direction_to_offset(player_after_turn.direction)
      let target_pos =
        vec2.Vec2(
          player_after_turn.grid_pos.x + offset.x,
          player_after_turn.grid_pos.y + offset.y,
        )

      // Handle tunnel wrapping (left-right edges)
      let wrapped_pos = wrap_position(target_pos)

      // Check if target position is walkable
      case is_walkable(maze, wrapped_pos) {
        True ->
          gs.Player(
            ..player_after_turn,
            grid_pos: wrapped_pos,
            move_accumulator: new_accumulator -. 1.0,
          )
        False ->
          // Can't move - wall blocking
          gs.Player(
            ..player_after_turn,
            move_accumulator: new_accumulator -. 1.0,
          )
      }
    }
    False ->
      // Not enough time accumulated yet
      gs.Player(..player, move_accumulator: new_accumulator)
  }
}

/// Wrap position for tunnel (left-right wrap at edges)
fn wrap_position(pos: vec2.Vec2(Int)) -> vec2.Vec2(Int) {
  let wrapped_x = case pos.x {
    x if x < 0 -> 27
    // Wrap from left to right
    x if x > 27 -> 0
    // Wrap from right to left
    x -> x
  }
  vec2.Vec2(wrapped_x, pos.y)
}

/// Try to execute buffered turn
fn try_turn(player: gs.Player, maze: List(List(gs.Tile))) -> gs.Player {
  // Check if player wants to turn
  case player.next_direction == player.direction {
    True -> player
    // No turn requested
    False -> {
      // Try turning in buffered direction
      let offset = gs.direction_to_offset(player.next_direction)
      let target_pos =
        vec2.Vec2(player.grid_pos.x + offset.x, player.grid_pos.y + offset.y)

      case is_walkable(maze, target_pos) {
        True ->
          // Can turn - execute buffered turn
          gs.Player(..player, direction: player.next_direction)
        False ->
          // Can't turn yet - keep buffered direction
          player
      }
    }
  }
}

/// Helper to get list element at index
fn list_at(list: List(a), index: Int) -> Result(a, Nil) {
  case index < 0 {
    True -> Error(Nil)
    False ->
      case list, index {
        [], _ -> Error(Nil)
        [first, ..], 0 -> Ok(first)
        [_, ..rest], n -> list_at(rest, n - 1)
      }
  }
}
