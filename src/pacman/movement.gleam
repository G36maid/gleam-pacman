/// Movement system for Pac-Man - grid-based movement with turn buffering
import pacman/game_state as gs
import vec/vec2

/// Check if a tile is walkable
pub fn is_walkable(maze: List(List(gs.Tile)), pos: vec2.Vec2(Int)) -> Bool {
  case list_at(maze, pos.y) {
    Ok(row) ->
      case list_at(row, pos.x) {
        Ok(gs.Wall) -> False
        Ok(_) -> True
        Error(_) -> False
      }
    Error(_) -> False
  }
}

/// Move player with grid-based movement and turn buffering
pub fn move_player(
  player: gs.Player,
  maze: List(List(gs.Tile)),
  _delta_seconds: Float,
) -> gs.Player {
  // Try to execute buffered turn first
  let player_after_turn = try_turn(player, maze)

  // Move in current direction
  let offset = gs.direction_to_offset(player_after_turn.direction)
  let target_pos =
    vec2.Vec2(
      player_after_turn.grid_pos.x + offset.x,
      player_after_turn.grid_pos.y + offset.y,
    )

  // Check if target position is walkable
  case is_walkable(maze, target_pos) {
    True -> gs.Player(..player_after_turn, grid_pos: target_pos)
    False ->
      // Can't move - wall blocking
      player_after_turn
  }
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
