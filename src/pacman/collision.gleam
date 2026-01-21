/// Collision detection for Pac-Man - dots, power pellets, and ghosts
import pacman/game_state as gs
import vec/vec2

/// Result of checking collision with tiles
pub type CollisionResult {
  CollisionResult(
    ate_dot: Bool,
    ate_power_pellet: Bool,
    updated_maze: List(List(gs.Tile)),
    dots_remaining: Int,
  )
}

/// Check if player ate any dots/pellets at current position
pub fn check_dot_collision(
  player_pos: vec2.Vec2(Int),
  maze: List(List(gs.Tile)),
) -> CollisionResult {
  // Get tile at player position
  case get_tile(maze, player_pos) {
    Ok(gs.Dot) -> {
      // Eat the dot
      let updated_maze = set_tile(maze, player_pos, gs.Empty)
      let dots_remaining = count_collectibles(updated_maze)
      CollisionResult(
        ate_dot: True,
        ate_power_pellet: False,
        updated_maze: updated_maze,
        dots_remaining: dots_remaining,
      )
    }
    Ok(gs.PowerPellet) -> {
      // Eat the power pellet
      let updated_maze = set_tile(maze, player_pos, gs.Empty)
      let dots_remaining = count_collectibles(updated_maze)
      CollisionResult(
        ate_dot: False,
        ate_power_pellet: True,
        updated_maze: updated_maze,
        dots_remaining: dots_remaining,
      )
    }
    _ -> {
      // No collision
      let dots_remaining = count_collectibles(maze)
      CollisionResult(
        ate_dot: False,
        ate_power_pellet: False,
        updated_maze: maze,
        dots_remaining: dots_remaining,
      )
    }
  }
}

/// Get tile at position
fn get_tile(
  maze: List(List(gs.Tile)),
  pos: vec2.Vec2(Int),
) -> Result(gs.Tile, Nil) {
  case list_at(maze, pos.y) {
    Ok(row) -> list_at(row, pos.x)
    Error(_) -> Error(Nil)
  }
}

/// Set tile at position
fn set_tile(
  maze: List(List(gs.Tile)),
  pos: vec2.Vec2(Int),
  new_tile: gs.Tile,
) -> List(List(gs.Tile)) {
  maze
  |> list_index_map(fn(row, y) {
    case y == pos.y {
      True ->
        row
        |> list_index_map(fn(tile, x) {
          case x == pos.x {
            True -> new_tile
            False -> tile
          }
        })
      False -> row
    }
  })
}

/// Count remaining dots and power pellets
fn count_collectibles(maze: List(List(gs.Tile))) -> Int {
  maze
  |> list_fold(0, fn(acc, row) {
    row
    |> list_fold(acc, fn(row_acc, tile) {
      case tile {
        gs.Dot | gs.PowerPellet -> row_acc + 1
        _ -> row_acc
      }
    })
  })
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

/// Helper to map list with index
fn list_index_map(list: List(a), f: fn(a, Int) -> b) -> List(b) {
  list_index_map_loop(list, f, 0, [])
}

fn list_index_map_loop(
  list: List(a),
  f: fn(a, Int) -> b,
  index: Int,
  acc: List(b),
) -> List(b) {
  case list {
    [] -> list_reverse(acc)
    [first, ..rest] -> {
      let result = f(first, index)
      list_index_map_loop(rest, f, index + 1, [result, ..acc])
    }
  }
}

/// Helper to reverse list
fn list_reverse(list: List(a)) -> List(a) {
  list_reverse_loop(list, [])
}

fn list_reverse_loop(list: List(a), acc: List(a)) -> List(a) {
  case list {
    [] -> acc
    [first, ..rest] -> list_reverse_loop(rest, [first, ..acc])
  }
}

/// Helper to fold list
fn list_fold(list: List(a), initial: b, f: fn(b, a) -> b) -> b {
  case list {
    [] -> initial
    [first, ..rest] -> list_fold(rest, f(initial, first), f)
  }
}
